import Inventory from '../models/Inventory.js';
import InventoryMovement from '../models/InventoryMovement.js';
import { dispatchNotification } from './notificationService.js';

export const MOVEMENT_TYPES = {
  PURCHASE: 'Purchase',
  RETURN: 'Return',
  CONSUMPTION: 'Consumption',
  ADJUSTMENT: 'Adjustment',
  RESERVATION: 'Reservation',
  RELEASE: 'Release',
};

/**
 * Record an auditable inventory movement and atomically update item stock balance (Phase 3, 7.3)
 */
export const recordInventoryMovement = async ({
  shopId,
  inventoryItemId,
  orderId = null,
  movementType,
  quantity,
  reference = null,
  reason = '',
  recordedBy = 'System',
  allowNegative = false,
}) => {
  if (!shopId) throw new Error('Shop ID is required to record inventory movement');
  if (!inventoryItemId) throw new Error('Inventory Item ID is required');

  const item = await Inventory.findOne({ _id: inventoryItemId, shopId });
  if (!item) {
    const notFoundErr = new Error('Inventory item not found');
    notFoundErr.statusCode = 404;
    throw notFoundErr;
  }

  const rawQty = Number(quantity);
  if (isNaN(rawQty) || rawQty === 0) {
    const err = new Error('A non-zero numeric movement quantity is required');
    err.statusCode = 400;
    throw err;
  }

  // Calculate signed quantity based on movement type
  let signedQty = rawQty;
  if (movementType === MOVEMENT_TYPES.CONSUMPTION) {
    signedQty = -Math.abs(rawQty);
  } else if (movementType === MOVEMENT_TYPES.PURCHASE || movementType === MOVEMENT_TYPES.RETURN) {
    signedQty = Math.abs(rawQty);
  } else if (movementType === MOVEMENT_TYPES.ADJUSTMENT) {
    if (!reason || !reason.trim()) {
      const err = new Error('A reason is required to record a manual inventory adjustment');
      err.statusCode = 400;
      throw err;
    }
    signedQty = rawQty;
  }

  const previousBalance = Math.round((Number(item.quantity) || 0) * 100) / 100;
  const newBalance = Math.round((previousBalance + signedQty) * 100) / 100;

  if (newBalance < 0 && !allowNegative) {
    const err = new Error(
      `Movement exceeds available stock for "${item.itemName}". Current: ${previousBalance} ${item.unit || 'units'}, Attempted reduction: ${Math.abs(signedQty)} ${item.unit || 'units'}. Resulting stock cannot be negative.`
    );
    err.statusCode = 400;
    err.currentBalance = previousBalance;
    err.requiredQuantity = Math.abs(signedQty);
    throw err;
  }

  // Update item balance transactionally
  item.quantity = newBalance;
  item.version = (item.version || 1) + 1;
  const updatedItem = await item.save();

  // Create immutable movement record
  const movement = await InventoryMovement.create({
    shopId,
    inventoryItemId: item._id,
    orderId: orderId || null,
    movementType,
    quantity: signedQty,
    previousBalance,
    newBalance,
    reference: reference || (orderId ? `Order ${orderId}` : null),
    reason: (reason && reason.trim()) || `${movementType} of ${Math.abs(signedQty)} ${item.unit || 'units'}`,
    recordedBy,
    createdAt: new Date().toISOString(),
  });

  // Check low stock threshold alert
  const threshold = updatedItem.minQuantity !== undefined ? updatedItem.minQuantity : 5;
  if (updatedItem.quantity <= threshold) {
    await dispatchNotification({
      shopId,
      title: '⚠️ Low Stock Alert',
      message: `${updatedItem.itemName} stock dropped to ${updatedItem.quantity} ${updatedItem.unit || 'units'} (Minimum: ${threshold}).`,
      type: 'low_stock',
      sendPush: true,
    }).catch((notifErr) => {
      console.warn('Low stock notification skipped:', notifErr.message);
    });
  }

  return { item: updatedItem, movement };
};

/**
 * Retrieve chronological movements for an inventory item
 */
export const getItemMovements = async (inventoryItemId, shopId) => {
  return InventoryMovement.find({ inventoryItemId, shopId }).sort({ createdAt: -1 });
};

/**
 * Reconcile item stock against movement history
 */
export const reconcileItemStock = async (inventoryItemId, shopId) => {
  const item = await Inventory.findOne({ _id: inventoryItemId, shopId });
  if (!item) return null;

  const movements = await InventoryMovement.find({ inventoryItemId, shopId });
  const movementSum = movements.reduce((sum, m) => sum + (Number(m.quantity) || 0), 0);
  const roundedSum = Math.round(movementSum * 100) / 100;
  const currentStock = Math.round((Number(item.quantity) || 0) * 100) / 100;
  const difference = Math.round((currentStock - roundedSum) * 100) / 100;

  return {
    itemId: item._id,
    itemName: item.itemName,
    currentStock,
    movementSum: roundedSum,
    difference,
    hasDiscrepancy: difference !== 0,
    movementCount: movements.length,
  };
};

export default {
  recordInventoryMovement,
  getItemMovements,
  reconcileItemStock,
  MOVEMENT_TYPES,
};

