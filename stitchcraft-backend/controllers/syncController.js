import Customer from '../models/Customer.js';
import Order from '../models/Order.js';
import Shop from '../models/Shop.js';
import Repair from '../models/Repair.js';
import Inventory from '../models/Inventory.js';
import InventoryMovement from '../models/InventoryMovement.js';
import LedgerEntry from '../models/LedgerEntry.js';
import Measurement from '../models/Measurement.js';
import Karigar from '../models/Karigar.js';
import Delivery from '../models/Delivery.js';
import Payment from '../models/Payment.js';
import Transaction from '../models/Transaction.js';
import SyncMutation from '../models/SyncMutation.js';
import { updateOrderService, createOrderService, deleteOrderService } from '../services/orderService.js';
import { updateCustomerService, createCustomerService, deleteCustomerService } from '../services/customerService.js';
import { recordOrderPaymentAtomic } from '../services/financialService.js';
import { recordInventoryMovement, MOVEMENT_TYPES } from '../services/inventoryService.js';
import { sortMutationsByDependency, SYNC_REGISTRY } from '../config/syncRegistry.js';

// @desc    Batch push client mutations respecting dependency precedence (Phase 5, 9.2)
// @route   POST /api/sync/push
// @access  Private
export const pushMutations = async (req, res) => {
  try {
    const shopId = req.user.shopId;
    const { mutations } = req.body;

    if (!Array.isArray(mutations)) {
      return res.status(400).json({ message: 'Payload must contain a mutations array' });
    }

    // Sort mutations strictly by dependency precedence:
    // Shop -> Customers/Karigars -> Measurements/Inventory -> Orders/Repairs -> Payments/Expenses -> Deliveries/Movements
    const sortedMutations = sortMutationsByDependency(mutations);
    const results = [];

    for (const m of sortedMutations) {
      const mutationId = m.clientMutationId || m.client_mutation_id || m.id;
      const entityType = (m.entityType || m.entity_type || m.table_name || '').toLowerCase();
      const entityId = m.entityId || m.entity_id || m.record_id;
      const operation = (m.operation || m.action || '').toLowerCase();
      const baseVersion = m.baseVersion ?? m.base_version;
      const payload = m.payload || {};

      if (!mutationId) {
        results.push({
          clientMutationId: null,
          status: 'failed',
          error: 'Missing clientMutationId',
        });
        continue;
      }

      // Check if already processed (server idempotency - Phase 2, 6.3 & Phase 5, 9.1)
      const existing = await SyncMutation.findOne({ shopId, mutationId });
      if (existing) {
        results.push({
          clientMutationId: mutationId,
          status: 'synced',
          isReplay: true,
          data: existing.response,
        });
        continue;
      }

      try {
        let resultData = null;

        // 0. Shop Settings (Priority 0)
        if (entityType === 'shops' || entityType === 'shop_settings') {
          const shop = await Shop.findById(shopId);
          if (shop) {
            Object.assign(shop, payload);
            shop.version = Number(shop.version || 1) + 1;
            resultData = await shop.save();
          }
        }

        // 1. Customers (Priority 2)
        else if (entityType === 'customers') {
          if (operation === 'create') {
            resultData = await createCustomerService({ ...payload, idempotencyKey: mutationId, shopId });
          } else if (operation === 'update') {
            resultData = await updateCustomerService(entityId, { ...payload, base_version: baseVersion }, shopId);
          } else if (operation === 'delete') {
            resultData = await deleteCustomerService(entityId, shopId);
          }
        }

        // 2. Karigars / Shop Members (Priority 2)
        else if (entityType === 'karigars') {
          if (operation === 'create') {
            resultData = await Karigar.create({ ...payload, shopId, version: 1 });
          } else if (operation === 'update') {
            const member = await Karigar.findOne({ _id: entityId, shopId });
            if (!member) throw Object.assign(new Error('Karigar not found'), { statusCode: 404 });
            if (baseVersion !== undefined && baseVersion !== null && Number(member.version || 1) !== Number(baseVersion)) {
              throw Object.assign(new Error('Conflict: concurrent modification detected'), {
                statusCode: 409,
                serverVersion: member.version || 1,
                currentData: member.toJSON ? member.toJSON() : member,
              });
            }
            Object.assign(member, payload);
            member.version = Number(member.version || 1) + 1;
            resultData = await member.save();
          }
        }

        // 3. Measurements (Priority 3, child of customer)
        else if (entityType === 'measurements') {
          if (operation === 'create') {
            resultData = await Measurement.create({ ...payload, shopId, version: 1 });
          } else if (operation === 'update') {
            const measure = await Measurement.findOne({ _id: entityId, shopId });
            if (!measure) throw Object.assign(new Error('Measurement record not found'), { statusCode: 404 });
            if (baseVersion !== undefined && baseVersion !== null && Number(measure.version || 1) !== Number(baseVersion)) {
              throw Object.assign(new Error('Conflict: concurrent modification detected'), {
                statusCode: 409,
                serverVersion: measure.version || 1,
                currentData: measure.toJSON ? measure.toJSON() : measure,
              });
            }
            Object.assign(measure, payload);
            measure.version = Number(measure.version || 1) + 1;
            resultData = await measure.save();
          }
        }

        // 4. Inventory (Priority 3, transactional movement)
        else if (entityType === 'inventory') {
          if (operation === 'create') {
            resultData = await Inventory.create({ ...payload, shopId, version: 1 });
          } else if (operation === 'update') {
            const item = await Inventory.findOne({ _id: entityId, shopId });
            if (!item) throw Object.assign(new Error('Inventory item not found'), { statusCode: 404 });
            if (baseVersion !== undefined && baseVersion !== null && Number(item.version || 1) !== Number(baseVersion)) {
              throw Object.assign(new Error('Conflict: concurrent modification detected'), {
                statusCode: 409,
                serverVersion: item.version || 1,
                currentData: item.toJSON ? item.toJSON() : item,
              });
            }
            Object.assign(item, payload);
            item.version = Number(item.version || 1) + 1;
            resultData = await item.save();
          } else if (operation === 'delete') {
            await Inventory.deleteOne({ _id: entityId, shopId });
            resultData = { deleted: true };
          }
        }

        // 5. Orders (Priority 4)
        else if (entityType === 'orders') {
          if (operation === 'create') {
            resultData = await createOrderService({ ...payload, idempotencyKey: mutationId, shopId }, shopId);
          } else if (operation === 'update') {
            resultData = await updateOrderService(entityId, { ...payload, base_version: baseVersion }, shopId, req.user.name);
          } else if (operation === 'delete') {
            resultData = await deleteOrderService(entityId, shopId);
          }
        }

        // 5b. Repairs (Priority 4, sibling of orders)
        else if (entityType === 'repairs') {
          if (operation === 'create') {
            resultData = await Repair.create({ ...payload, shopId, version: 1 });
          } else if (operation === 'update') {
            const rep = await Repair.findOne({ _id: entityId, shopId });
            if (!rep) throw Object.assign(new Error('Repair record not found'), { statusCode: 404 });
            if (baseVersion !== undefined && baseVersion !== null && Number(rep.version || 1) !== Number(baseVersion)) {
              throw Object.assign(new Error('Conflict: concurrent modification detected'), {
                statusCode: 409,
                serverVersion: rep.version || 1,
                currentData: rep.toJSON ? rep.toJSON() : rep,
              });
            }
            Object.assign(rep, payload);
            rep.version = Number(rep.version || 1) + 1;
            resultData = await rep.save();
          } else if (operation === 'delete') {
            await Repair.deleteOne({ _id: entityId, shopId });
            resultData = { deleted: true };
          }
        }

        // 6. Payments / Order Payments (Priority 5, immutable event)
        else if (entityType === 'order_payments' || entityType === 'payments') {
          if (operation === 'create' || operation === 'payment') {
            resultData = await recordOrderPaymentAtomic({
              shopId,
              orderId: payload.orderId || entityId,
              amount: payload.amount,
              paymentType: payload.paymentType || payload.payment_method || 'Cash',
              idempotencyKey: mutationId,
              recordedBy: req.user.name || 'Owner',
            });
          }
        }

        // 7. Expenses / Ledger Entries (Priority 5)
        else if (entityType === 'expenses') {
          if (operation === 'create') {
            resultData = await LedgerEntry.create({ ...payload, shopId, version: 1 });
          } else if (operation === 'update') {
            const entry = await LedgerEntry.findOne({ _id: entityId, shopId });
            if (!entry) throw Object.assign(new Error('Expense entry not found'), { statusCode: 404 });
            if (baseVersion !== undefined && baseVersion !== null && Number(entry.version || 1) !== Number(baseVersion)) {
              throw Object.assign(new Error('Conflict: concurrent modification detected'), {
                statusCode: 409,
                serverVersion: entry.version || 1,
                currentData: entry.toJSON ? entry.toJSON() : entry,
              });
            }
            Object.assign(entry, payload);
            entry.version = Number(entry.version || 1) + 1;
            resultData = await entry.save();
          } else if (operation === 'delete') {
            await LedgerEntry.deleteOne({ _id: entityId, shopId });
            resultData = { deleted: true };
          }
        }

        // 8. Inventory Movements (Priority 6, append-only)
        else if (entityType === 'inventory_movements') {
          resultData = await recordInventoryMovement({
            shopId,
            inventoryItemId: payload.inventoryItemId || entityId,
            orderId: payload.orderId || null,
            movementType: payload.movementType || MOVEMENT_TYPES.ADJUSTMENT,
            quantity: payload.quantity,
            reason: payload.reason || 'Sync movement',
            reference: payload.reference || null,
            recordedBy: req.user.name || 'Owner',
          });
        }

        // 9. Deliveries (Priority 6)
        else if (entityType === 'deliveries') {
          const order = await Order.findOne({ _id: payload.orderId || entityId, shopId });
          if (order) {
            resultData = await Delivery.create({
              shopId,
              orderId: order._id,
              deliveredAt: new Date().toISOString(),
              recipientName: payload.recipientName || order.customerName,
              allowCredit: Boolean(payload.allowCredit),
              creditReason: payload.creditReason || '',
            });
          }
        }

        // 10. Karigar Assignments (Priority 6)
        else if (entityType === 'karigar_assignments') {
          const targetOrder = await Order.findOne({ _id: payload.orderId || entityId, shopId });
          if (targetOrder) {
            targetOrder.assignedKarigar = payload.karigarId || null;
            targetOrder.version = Number(targetOrder.version || 1) + 1;
            resultData = await targetOrder.save();
          }
        }

        // Commit server mutation record for replay resilience
        await SyncMutation.create({
          shopId,
          mutationId,
          entityType,
          entityId,
          operation,
          statusCode: 200,
          response: resultData,
          createdAt: new Date().toISOString(),
        });

        results.push({
          clientMutationId: mutationId,
          status: 'synced',
          serverVersion: resultData?.version,
          data: resultData,
        });
      } catch (err) {
        if (err.statusCode === 409) {
          results.push({
            clientMutationId: mutationId,
            status: 'conflict',
            serverVersion: err.serverVersion,
            currentData: err.currentData,
            error: err.message,
          });
        } else {
          results.push({
            clientMutationId: mutationId,
            status: 'failed',
            error: err.message,
          });
        }
      }
    }

    res.json({ results });
  } catch (error) {
    console.error('Batch sync push error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Pull remote changes across all registry entities (Phase 5, 9.2)
// @route   GET /api/sync/pull
// @access  Private
export const pullChanges = async (req, res) => {
  try {
    const shopId = req.user.shopId;
    const since = req.query.since;

    const filter = { shopId };
    if (since) {
      filter.updatedAt = { $gt: since };
    }

    const [customers, karigars, measurements, inventory, inventoryMovements, orders, transactions, expenses] = await Promise.all([
      Customer.find({ shopId, isDeleted: { $ne: true } }),
      Karigar.find({ shopId }),
      Measurement.find({ shopId }),
      Inventory.find({ shopId }),
      InventoryMovement.find({ shopId }),
      Order.find({ shopId }),
      Transaction.find({ shopId }),
      LedgerEntry.find({ shopId }),
    ]);

    res.json({
      customers: customers.map((c) => ({ ...c.toJSON(), version: c.version || 1 })),
      karigars: karigars.map((k) => ({ ...k.toJSON(), version: k.version || 1 })),
      measurements: measurements.map((m) => ({ ...m.toJSON(), version: m.version || 1 })),
      inventory: inventory.map((i) => ({ ...i.toJSON(), version: i.version || 1 })),
      inventoryMovements: inventoryMovements.map((im) => ({ ...im.toJSON() })),
      orders: orders.map((o) => ({ ...o.toJSON(), version: o.version || 1 })),
      payments: transactions.map((t) => ({ ...t.toJSON() })),
      expenses: expenses.map((e) => ({ ...e.toJSON(), version: e.version || 1 })),
      serverTime: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Batch sync pull error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get dynamic sync registry metadata (Phase 5, 9.1)
// @route   GET /api/sync/registry
// @access  Private
export const getSyncRegistryMetadata = async (req, res) => {
  res.json({
    version: '1.0',
    registry: SYNC_REGISTRY,
    uploadOrder: [
      'shop',
      'customers',
      'karigars',
      'measurements',
      'inventory',
      'orders',
      'repair_jobs',
      'order_payments',
      'expenses',
      'inventory_movements',
      'deliveries',
    ],
  });
};

// @desc    Get basic sync status
// @route   GET /api/sync/status
// @access  Private
export const getSyncStatus = async (req, res) => {
  res.json({
    status: 'healthy',
    shopId: req.user.shopId,
    serverTime: new Date().toISOString(),
  });
};

export default {
  pushMutations,
  pullChanges,
  getSyncRegistryMetadata,
  getSyncStatus,
};
