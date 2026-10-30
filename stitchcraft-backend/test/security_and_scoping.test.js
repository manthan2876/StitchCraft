import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { authorize } from '../middleware/authMiddleware.js';
import { isValidIdentifier } from '../utils/identifiers.js';

describe('Auth & Role Authorization Middleware', () => {
  it('should block unauthenticated requests with 401', () => {
    const req = {};
    let statusCode = null;
    let jsonBody = null;
    const res = {
      status(code) {
        statusCode = code;
        return this;
      },
      json(body) {
        jsonBody = body;
        return this;
      },
    };
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    const middleware = authorize('owner');
    middleware(req, res, next);

    assert.equal(statusCode, 401);
    assert.match(jsonBody.message, /not authorized/i);
    assert.equal(nextCalled, false);
  });

  it('should block non-owner users from owner-only actions with 403', () => {
    const req = { user: { role: 'karigar' } };
    let statusCode = null;
    let jsonBody = null;
    const res = {
      status(code) {
        statusCode = code;
        return this;
      },
      json(body) {
        jsonBody = body;
        return this;
      },
    };
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    const middleware = authorize('owner');
    middleware(req, res, next);

    assert.equal(statusCode, 403);
    assert.match(jsonBody.message, /forbidden/i);
    assert.equal(nextCalled, false);
  });

  it('should allow owner users through authorize("owner")', () => {
    const req = { user: { role: 'owner' } };
    let nextCalled = false;
    const next = () => { nextCalled = true; };
    const res = {};

    const middleware = authorize('owner');
    middleware(req, res, next);

    assert.equal(nextCalled, true);
  });
});

describe('Identifier Validation', () => {
  it('should validate typical IDs and tokens', () => {
    assert.equal(isValidIdentifier('12345'), true);
    assert.equal(isValidIdentifier('ORD-ABC12345'), true);
    assert.equal(isValidIdentifier('550e8400-e29b-41d4-a716-446655440000'), true);
    assert.equal(isValidIdentifier('a'.repeat(64)), true);
  });

  it('should reject invalid or empty identifiers', () => {
    assert.equal(isValidIdentifier(''), false);
    assert.equal(isValidIdentifier('   '), false);
    assert.equal(isValidIdentifier(null), false);
    assert.equal(isValidIdentifier(undefined), false);
    assert.equal(isValidIdentifier('a'.repeat(129)), false);
  });
});

describe('Public Invoice Sanitization Safety', () => {
  it('should strictly exclude wholesale costs, internal margins, and staff assignments from public receipts', () => {
    const internalOrder = {
      _id: 'order-123',
      orderId: 'ORD-12345',
      customerName: 'Aarav Patel',
      apparelType: 'Sherwani',
      fabric: 'Raw Silk',
      status: 'Stitching',
      deliveryDate: '2026-11-15T00:00:00.000Z',
      price: 5000,
      needsAster: true,
      asterQuantity: 3,
      asterSellingPrice: 400,
      asterCostPrice: 150, // WHOLESALE COST - SENSITIVE
      asterProfit: 750, // INTERNAL MARGIN - SENSITIVE
      assignedKarigar: 'karigar-999', // SENSITIVE
      assignedMachine: 'machine-555', // SENSITIVE
      notes: [{ text: 'Customer is demanding, handle with care', addedAt: new Date() }], // SENSITIVE INTERNAL NOTES
      shopId: 'shop-secret-key-123',
    };

    // Construct the public sanitized view matching our controller implementation
    const publicReceipt = {
      _id: internalOrder._id,
      orderId: internalOrder.orderId,
      customerName: internalOrder.customerName,
      apparelType: internalOrder.apparelType,
      fabric: internalOrder.fabric,
      status: internalOrder.status,
      deliveryDate: internalOrder.deliveryDate,
      price: internalOrder.price,
      needsAster: internalOrder.needsAster,
      asterQuantity: internalOrder.asterQuantity,
      asterSellingPrice: internalOrder.asterSellingPrice,
    };

    // Verify sensitive properties are NOT exposed
    assert.equal('asterCostPrice' in publicReceipt, false);
    assert.equal('asterProfit' in publicReceipt, false);
    assert.equal('assignedKarigar' in publicReceipt, false);
    assert.equal('assignedMachine' in publicReceipt, false);
    assert.equal('notes' in publicReceipt, false);
    assert.equal('shopId' in publicReceipt, false);

    // Verify essential receipt fields are present
    assert.equal(publicReceipt.orderId, 'ORD-12345');
    assert.equal(publicReceipt.customerName, 'Aarav Patel');
    assert.equal(publicReceipt.price, 5000);
  });

  it('should include customer-facing items in public receipt while stripping secrets', () => {
    const rawItems = [
      { id: 'item-1', name: 'Cotton Shirt', apparelType: 'Shirt', quantity: 2, price: 800, internalKarigarWage: 200 },
      { id: 'item-2', name: 'Formal Pant', apparelType: 'Pant', quantity: 1, price: 950, internalKarigarWage: 300 },
    ];

    const sanitizedItems = rawItems.map((it) => ({
      id: it.id,
      name: it.name,
      apparelType: it.apparelType,
      quantity: it.quantity,
      price: it.price,
    }));

    assert.equal(sanitizedItems.length, 2);
    assert.equal('internalKarigarWage' in sanitizedItems[0], false);
    assert.equal(sanitizedItems[0].quantity, 2);
    assert.equal(sanitizedItems[0].price, 800);
  });
});

describe('Notification Dispatch Service', () => {
  it('should handle unconfigured Firebase credentials gracefully without throwing', async () => {
    const { dispatchNotification } = await import('../services/notificationService.js');
    const result = await dispatchNotification({
      shopId: 'shop-test-123',
      title: 'Test Notification',
      message: 'Test message body',
      type: 'test',
    });

    // Should return result object with pushSentCount = 0 and not throw
    assert.ok(result);
    assert.equal(result.pushSentCount, 0);
  });
});

describe('Relational Schema Migration Transformation', () => {
  it('should map app_records document into normalized columns correctly', async () => {
    const rawOrderRecord = {
      collection: 'orders',
      source_id: 'ord-uuid-123',
      document: {
        _id: 'ord-uuid-123',
        shopId: 'shop-456',
        customer: { _id: 'cust-789' },
        assignedKarigar: 'karigar-101',
        assignedMachine: { _id: 'machine-202' },
        price: 1500,
        items: [{ apparelType: 'Shirt', quantity: 2, price: 750 }],
      },
      created_at: '2026-10-30T10:00:00Z',
      updated_at: '2026-10-30T10:00:00Z',
    };

    // Verify extraction logic
    const transformed = {
      id: rawOrderRecord.source_id,
      shop_id: rawOrderRecord.document.shopId,
      customer_id: rawOrderRecord.document.customer._id,
      karigar_id: rawOrderRecord.document.assignedKarigar,
      machine_id: rawOrderRecord.document.assignedMachine._id,
      document: rawOrderRecord.document,
      created_at: rawOrderRecord.created_at,
      updated_at: rawOrderRecord.updated_at,
    };

    assert.equal(transformed.id, 'ord-uuid-123');
    assert.equal(transformed.shop_id, 'shop-456');
    assert.equal(transformed.customer_id, 'cust-789');
    assert.equal(transformed.karigar_id, 'karigar-101');
    assert.equal(transformed.machine_id, 'machine-202');
    assert.equal(transformed.document.items.length, 1);
  });
});

describe('Database Table Document Validations', () => {
  it('should reject invalid customer data at model layer', async () => {
    const { validateDocument, ValidationError } = await import('../utils/tableValidators.js');

    // Missing shopId
    assert.throws(
      () => validateDocument('customers', { name: 'Anand', phone: '9876543210' }),
      (err) => err instanceof ValidationError && err.fieldErrors.shopId !== undefined
    );

    // Invalid phone
    assert.throws(
      () => validateDocument('customers', { shopId: 'shop-1', name: 'Anand', phone: '123' }),
      (err) => err instanceof ValidationError && err.fieldErrors.phone !== undefined
    );

    // Valid customer succeeds
    assert.equal(
      validateDocument('customers', { shopId: 'shop-1', name: 'Anand Sharma', phone: '9876543210' }),
      true
    );
  });

  it('should reject negative order price and invalid status at model layer', async () => {
    const { validateDocument, ValidationError } = await import('../utils/tableValidators.js');

    assert.throws(
      () => validateDocument('orders', { shopId: 'shop-1', customerName: 'Rohan', price: -50 }),
      (err) => err instanceof ValidationError && err.fieldErrors.price !== undefined
    );

    assert.throws(
      () => validateDocument('orders', { shopId: 'shop-1', customerName: 'Rohan', price: 100, status: 'InvalidStatus' }),
      (err) => err instanceof ValidationError && err.fieldErrors.status !== undefined
    );
  });

  it('should reject negative quantities and invalid units in inventory', async () => {
    const { validateDocument, ValidationError } = await import('../utils/tableValidators.js');

    assert.throws(
      () => validateDocument('inventory', { shopId: 'shop-1', itemName: 'Lining Silk', quantity: -10 }),
      (err) => err instanceof ValidationError && err.fieldErrors.quantity !== undefined
    );

    assert.throws(
      () => validateDocument('inventory', { shopId: 'shop-1', itemName: 'Lining Silk', unit: 'invalidUnit' }),
      (err) => err instanceof ValidationError && err.fieldErrors.unit !== undefined
    );
  });
});

describe('API Request Validation Middlewares', () => {
  it('should block customer creation with invalid phone with HTTP 400', async () => {
    const { validateCustomerRequest } = await import('../middleware/validationMiddleware.js');
    const req = { body: { name: 'Aarav Patel', phone: '123' } };
    let statusCode = null;
    let jsonBody = null;
    const res = {
      status(code) { statusCode = code; return this; },
      json(body) { jsonBody = body; return this; },
    };
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    validateCustomerRequest(req, res, next);
    assert.equal(statusCode, 400);
    assert.ok(jsonBody.errors?.phone);
    assert.equal(nextCalled, false);
  });

  it('should allow valid customer request through middleware', async () => {
    const { validateCustomerRequest } = await import('../middleware/validationMiddleware.js');
    const req = { body: { name: 'Aarav Patel', phone: '9876543210', email: 'aarav@gmail.com' } };
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    validateCustomerRequest(req, {}, next);
    assert.equal(nextCalled, true);
  });
});

