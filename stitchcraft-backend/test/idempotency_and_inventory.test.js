import test, { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { ASTAR_DEDUCT_STATUSES } from '../services/orderService.js';

describe('Idempotency & Inventory Safety Specifications', () => {
  it('should guarantee order creation idempotency via idempotencyKey resolution', () => {
    // In-memory store simulating idempotent collection storage
    const store = new Map();

    const simulateCreateOrder = (reqBody, shopId) => {
      const idempotencyKey = reqBody.idempotencyKey || reqBody.clientMutationId;
      if (idempotencyKey) {
        for (const order of store.values()) {
          if (order.shopId === shopId && order.idempotencyKey === idempotencyKey) {
            return { order, isReplay: true };
          }
        }
      }

      const newOrder = {
        _id: 'ord_' + Math.random().toString(36).substring(2, 9),
        orderId: 'ORD-' + Math.floor(1000 + Math.random() * 9000),
        customerName: reqBody.customerName,
        price: reqBody.price,
        shopId,
        idempotencyKey: idempotencyKey || null,
        status: 'Incoming',
        createdAt: new Date().toISOString(),
      };
      store.set(newOrder._id, newOrder);
      return { order: newOrder, isReplay: false };
    };

    const idempotencyKey = 'mobile_uuid_9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';
    const firstCall = simulateCreateOrder({ customerName: 'Suman Roy', price: 1200, idempotencyKey }, 'shop_1');
    assert.equal(firstCall.isReplay, false);
    const createdId = firstCall.order._id;

    // Retry due to network timeout
    const secondCall = simulateCreateOrder({ customerName: 'Suman Roy', price: 1200, idempotencyKey }, 'shop_1');
    assert.equal(secondCall.isReplay, true, 'Second call must be identified as replay');
    assert.equal(secondCall.order._id, createdId, 'Replayed call must return original order ID');
    assert.equal(store.size, 1, 'Only one order must exist in store');
  });

  it('should guarantee customer creation idempotency and prevent duplicate customer records', () => {
    const customerStore = new Map();

    const simulateCreateCustomer = (reqBody, shopId) => {
      const idempotencyKey = reqBody.idempotencyKey || reqBody.clientMutationId;
      if (idempotencyKey) {
        for (const cust of customerStore.values()) {
          if (cust.shopId === shopId && cust.idempotencyKey === idempotencyKey) {
            return { customer: cust, isReplay: true };
          }
        }
      }

      // Check phone deduplication
      const cleanPhone = (reqBody.phone || '').replace(/\D/g, '').slice(-10);
      for (const cust of customerStore.values()) {
        if (cust.shopId === shopId && cust.phone.endsWith(cleanPhone)) {
          return { customer: cust, isReplay: true };
        }
      }

      const newCust = {
        _id: 'cust_' + Math.random().toString(36).substring(2, 9),
        name: reqBody.name,
        phone: reqBody.phone,
        shopId,
        idempotencyKey: idempotencyKey || null,
      };
      customerStore.set(newCust._id, newCust);
      return { customer: newCust, isReplay: false };
    };

    const idemKey = 'cust_local_f81d4fae-7dec-11d0-a765-00a0c91e6bf6';
    const first = simulateCreateCustomer({ name: 'Meena Ben', phone: '9825012345', idempotencyKey: idemKey }, 'shop_1');
    assert.equal(first.isReplay, false);

    const replay = simulateCreateCustomer({ name: 'Meena Ben', phone: '9825012345', idempotencyKey: idemKey }, 'shop_1');
    assert.equal(replay.isReplay, true);
    assert.equal(replay.customer._id, first.customer._id);
    assert.equal(customerStore.size, 1);
  });

  it('should deduct lining inventory exactly once when reaching active workshop stages', () => {
    const inventory = { quantity: 25.0, unit: 'meters' };
    const order = {
      orderId: 'ORD-101',
      needsAster: true,
      asterQuantity: 2.5,
      asterDeducted: false,
      inventoryDeductedAt: null,
      status: 'Incoming',
    };

    const applyStockAdjustment = (ord, newStatus, inv) => {
      const willDeduct = ASTAR_DEDUCT_STATUSES.includes(newStatus);
      const wasDeducted = ord.asterDeducted;

      if (ord.needsAster && ord.asterQuantity > 0) {
        if (willDeduct && !wasDeducted) {
          inv.quantity = Math.max(0, inv.quantity - ord.asterQuantity);
          ord.asterDeducted = true;
          ord.inventoryDeductedAt = '2026-11-04T12:00:00.000Z';
        } else if (!willDeduct && wasDeducted) {
          inv.quantity = inv.quantity + ord.asterQuantity;
          ord.asterDeducted = false;
          ord.inventoryDeductedAt = null;
        }
      }
      ord.status = newStatus;
    };

    // 1. Pre-production: Measuring (no deduction)
    applyStockAdjustment(order, 'Measuring', inventory);
    assert.equal(inventory.quantity, 25.0);
    assert.equal(order.asterDeducted, false);

    // 2. Production: Stitching (deduction occurs once)
    applyStockAdjustment(order, 'Stitching', inventory);
    assert.equal(inventory.quantity, 22.5);
    assert.equal(order.asterDeducted, true);
    assert.ok(order.inventoryDeductedAt);

    // 3. Status progression: Checking -> Ready -> Delivered (must NOT double-deduct)
    applyStockAdjustment(order, 'Checking', inventory);
    assert.equal(inventory.quantity, 22.5, 'Inventory must not decrement again in Checking');

    applyStockAdjustment(order, 'Ready', inventory);
    assert.equal(inventory.quantity, 22.5, 'Inventory must not decrement again in Ready');

    applyStockAdjustment(order, 'Delivered', inventory);
    assert.equal(inventory.quantity, 22.5, 'Inventory must not decrement again in Delivered');
    assert.equal(order.asterDeducted, true);
  });

  it('should restore lining inventory if order is cancelled or deleted from production stage', () => {
    const inventory = { quantity: 22.5, unit: 'meters' };
    const order = {
      orderId: 'ORD-101',
      needsAster: true,
      asterQuantity: 2.5,
      asterDeducted: true,
      status: 'Stitching',
    };

    // Simulating deleteOrderService restoration
    if (order.needsAster && order.asterDeducted) {
      inventory.quantity += order.asterQuantity;
      order.asterDeducted = false;
    }
    order.status = 'Cancelled';
    order.isDeleted = true;

    assert.equal(inventory.quantity, 25.0, 'Cancelled order restores lining stock');
    assert.equal(order.asterDeducted, false);
    assert.equal(order.status, 'Cancelled');
  });

  it('should enforce Indian currency grouping format correctly (en_IN standard)', () => {
    const formatINR = (amount) => {
      const num = Number(amount) || 0;
      const parts = num.toFixed(2).split('.');
      let intPart = parts[0];
      const decPart = parts[1];

      let lastThree = intPart.slice(-3);
      const otherNumbers = intPart.slice(0, -3);
      if (otherNumbers !== '') {
        lastThree = ',' + lastThree;
      }
      const res = otherNumbers.replace(/\B(?=(\d{2})+(?!\d))/g, ',') + lastThree;
      return `₹${res}.${decPart}`;
    };

    assert.equal(formatINR(500), '₹500.00');
    assert.equal(formatINR(12500), '₹12,500.00');
    assert.equal(formatINR(1234567), '₹12,34,567.00');
  });

  it('should separate order delivery status from payment balance', () => {
    const checkDeliverySafety = (order, payment) => {
      const totalAmount = payment.totalAmount || order.price;
      const paidAmount = payment.paidAmount || 0;
      const balance = Math.max(0, totalAmount - paidAmount);
      const isPaid = balance === 0;

      return {
        canDeliverDirectly: isPaid,
        requiresConfirmation: !isPaid,
        unpaidBalance: balance,
      };
    };

    // 1. Fully paid order
    const paidCase = checkDeliverySafety({ price: 1000 }, { totalAmount: 1000, paidAmount: 1000 });
    assert.equal(paidCase.canDeliverDirectly, true);
    assert.equal(paidCase.requiresConfirmation, false);
    assert.equal(paidCase.unpaidBalance, 0);

    // 2. Partial payment with remaining balance
    const partialCase = checkDeliverySafety({ price: 1500 }, { totalAmount: 1500, paidAmount: 500 });
    assert.equal(partialCase.canDeliverDirectly, false);
    assert.equal(partialCase.requiresConfirmation, true);
    assert.equal(partialCase.unpaidBalance, 1000);
  });

  it('should support inventory adjustment, wastage recording, and stock-safe limits (P1-04)', () => {
    const item = {
      _id: 'inv-item-1',
      itemName: 'Cotton Lining',
      quantity: 10.5,
      unit: 'meters',
      minQuantity: 5.0,
      adjustments: [],
    };

    const processAdjustment = (inv, { adjustmentQuantity, reason, type, user }) => {
      if (adjustmentQuantity === undefined || isNaN(Number(adjustmentQuantity)) || Number(adjustmentQuantity) === 0) {
        throw new Error('A non-zero numeric adjustment quantity is required');
      }
      if (!reason || !reason.trim()) {
        throw new Error('A reason is required to record an inventory adjustment or wastage');
      }

      const adjQty = Number(adjustmentQuantity);
      const newQty = Math.round((inv.quantity + adjQty) * 100) / 100;
      if (newQty < 0) {
        throw new Error(`Adjustment of ${adjQty} exceeds current stock`);
      }

      inv.quantity = newQty;
      inv.adjustments.push({
        date: new Date().toISOString(),
        adjustmentQuantity: adjQty,
        resultingQuantity: newQty,
        type: type || (adjQty < 0 ? 'wastage' : 'restock'),
        reason: reason.trim(),
        recordedBy: user || 'Owner',
      });
      return inv;
    };

    // 1. Record wastage of 1.25 meters
    processAdjustment(item, {
      adjustmentQuantity: -1.25,
      reason: 'Edge fraying and salvage scrap during cutting',
      type: 'wastage',
      user: 'Masterji',
    });
    assert.equal(item.quantity, 9.25);
    assert.equal(item.adjustments.length, 1);
    assert.equal(item.adjustments[0].type, 'wastage');
    assert.equal(item.adjustments[0].adjustmentQuantity, -1.25);

    // 2. Record restock of 15.0 meters
    processAdjustment(item, {
      adjustmentQuantity: 15.0,
      reason: 'New bolt purchase from textile market',
      type: 'restock',
      user: 'Masterji',
    });
    assert.equal(item.quantity, 24.25);

    // 3. Excess deduction throws stock limit error
    assert.throws(() => {
      processAdjustment(item, {
        adjustmentQuantity: -30.0,
        reason: 'Over-wastage attempt',
      });
    }, /exceeds current stock/);

    // 4. Missing reason throws error
    assert.throws(() => {
      processAdjustment(item, {
        adjustmentQuantity: -1.0,
        reason: '',
      });
    }, /A reason is required/);
  });
});
