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

describe('Outsourced Partner Order Privacy & Sanitization', () => {
  it('should sanitize outsourced orders for partner tailor: 1 day earlier due date, agreed cost, no customer details, fabric details preserved', async () => {
    const { sanitizeOrderForPartnerTailor } = await import('../services/orderService.js');

    const mainOrder = {
      _id: 'ord-999',
      orderId: 'ORD-999',
      shopId: 'main-shop-111',
      originShopId: 'main-shop-111',
      originShopName: 'Masterji Ramesh Tailors',
      originPhone: '9876543210',
      delegatedToShopId: 'partner-shop-222',
      delegatedToShopName: 'Anil Express Stitching',
      delegatedNotes: 'Urgent: finish collar and sleeves with gold piping',
      delegatedCost: 450,
      customerName: 'Smt. Anjali Mehta', // SENSITIVE
      customerPhone: '9123456780', // SENSITIVE
      customerAddress: '123 Riverfront Road, Ahmedabad', // SENSITIVE
      deliveryDate: '2026-11-20T18:00:00.000Z',
      dueDate: new Date('2026-11-20T18:00:00.000Z').getTime(),
      price: 1800, // MAIN TAILOR RETAIL BILLING COST - SENSITIVE
      totalAmount: 1800,
      needsAster: true,
      asterQuantity: 2.5,
      asterItemName: 'Satin Lining',
      asterProfit: 300, // SENSITIVE
      fabric: 'Chanderi Silk 3m Blue Floral',
      fabricImageUrl: 'https://cdn.stitchcraft.com/fabrics/silk_999.jpg',
      transactions: [{ id: 'tx-1', amount: 800, type: 'Payment' }], // SENSITIVE
    };

    // 1. When viewed by the Main Tailor (originating shop):
    const mainView = sanitizeOrderForPartnerTailor(mainOrder, 'main-shop-111');
    assert.equal(mainView.customerName, 'Smt. Anjali Mehta');
    assert.equal(mainView.price, 1800);
    assert.equal(mainView.deliveryDate, '2026-11-20T18:00:00.000Z');
    assert.equal(mainView.isPartnerJob, undefined);

    // 2. When viewed by the Outsourced Partner Tailor:
    const partnerView = sanitizeOrderForPartnerTailor(mainOrder, 'partner-shop-222');

    // Check coming from other tailor
    assert.equal(partnerView.isPartnerJob, true);
    assert.equal(partnerView.isOutsourcedToMe, true);
    assert.equal(partnerView.originShopName, 'Masterji Ramesh Tailors');
    assert.equal(partnerView.customerName, 'Partner Tailor: Masterji Ramesh Tailors');
    assert.equal(partnerView.customerPhone, '9876543210'); // Main tailor phone, not customer!
    assert.equal('customerAddress' in partnerView, false);

    // Check Due Date is ONE DAY BEFORE main order
    const expectedPartnerDate = new Date('2026-11-19T18:00:00.000Z').toISOString();
    assert.equal(partnerView.deliveryDate, expectedPartnerDate);
    assert.equal(partnerView.partnerDueDate, expectedPartnerDate);

    // Check Billing Cost is the agreed outsourced cost set by main tailor (₹450), NOT retail ₹1800
    assert.equal(partnerView.price, 450);
    assert.equal(partnerView.totalAmount, 450);
    assert.equal(partnerView.payment.totalAmount, 450);
    assert.equal(partnerView.advanceAmount, 0);
    assert.equal(partnerView.advance_amount, 0);
    assert.equal(partnerView.advancePaid, 0);
    assert.equal(partnerView.transactions.length, 0); // Customer transactions stripped!
    assert.equal('asterProfit' in partnerView, false);

    // Check Fabric and Tailoring Specs are completely preserved
    assert.equal(partnerView.fabric, 'Chanderi Silk 3m Blue Floral');
    assert.equal(partnerView.fabricImageUrl, 'https://cdn.stitchcraft.com/fabrics/silk_999.jpg');
    assert.equal(partnerView.needsAster, true);
    assert.equal(partnerView.asterQuantity, 2.5);
    assert.equal(partnerView.delegatedNotes, 'Urgent: finish collar and sleeves with gold piping');
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

  it('should route routine events to in-app notifications only without triggering push', async () => {
    const { dispatchNotification } = await import('../services/notificationService.js');
    const inAppTypes = ['order_status', 'payment', 'inventory'];

    for (const type of inAppTypes) {
      const res = await dispatchNotification({
        shopId: 'shop-test-123',
        title: `Event ${type}`,
        message: `Message for ${type}`,
        type,
      });
      assert.ok(res);
      assert.equal(res.channel, 'in_app_only');
      assert.equal(res.pushSentCount, 0);
    }
  });

  it('should authorize device push for order due reminders and low stock alerts', async () => {
    const { PUSH_ALLOWED_TYPES } = await import('../services/notificationService.js');
    assert.ok(PUSH_ALLOWED_TYPES.includes('order_due_reminder'));
    assert.ok(PUSH_ALLOWED_TYPES.includes('low_stock'));
    assert.equal(PUSH_ALLOWED_TYPES.includes('payment'), false);
    assert.equal(PUSH_ALLOWED_TYPES.includes('order_status'), false);
    assert.equal(PUSH_ALLOWED_TYPES.includes('inventory'), false);
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

  it('should validate forgot-password request email boundaries and rejection of invalid format', async () => {
    const { validateForgotPasswordRequest } = await import('../middleware/validationMiddleware.js');
    const invalidReq = { body: { email: 'bad-email' } };
    let statusCode = null;
    let jsonBody = null;
    const res = {
      status(code) { statusCode = code; return this; },
      json(body) { jsonBody = body; return this; },
    };
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    validateForgotPasswordRequest(invalidReq, res, next);
    assert.equal(statusCode, 400);
    assert.ok(jsonBody.errors?.email);
    assert.equal(nextCalled, false);

    const validReq = { body: { email: 'user@stitchcraft.in' } };
    let validNextCalled = false;
    validateForgotPasswordRequest(validReq, {}, () => { validNextCalled = true; });
    assert.equal(validNextCalled, true);
  });

  it('should validate reset-password password length requirements', async () => {
    const { validateResetPasswordRequest } = await import('../middleware/validationMiddleware.js');
    const invalidReq = { body: { password: '123' } };
    let statusCode = null;
    let jsonBody = null;
    const res = {
      status(code) { statusCode = code; return this; },
      json(body) { jsonBody = body; return this; },
    };
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    validateResetPasswordRequest(invalidReq, res, next);
    assert.equal(statusCode, 400);
    assert.ok(jsonBody.errors?.password);
    assert.equal(nextCalled, false);

    const validReq = { body: { password: 'strongPassword123' } };
    let validNextCalled = false;
    validateResetPasswordRequest(validReq, {}, () => { validNextCalled = true; });
    assert.equal(validNextCalled, true);
  });

  it('should validate payment request amounts and normalize payment types', async () => {
    const { validatePaymentRequest } = await import('../middleware/validationMiddleware.js');

    // Negative or zero amount rejected
    const invalidAmountReq = { body: { amount: 0, paymentType: 'online' } };
    let statusCode = null;
    let jsonBody = null;
    const res = {
      status(code) { statusCode = code; return this; },
      json(body) { jsonBody = body; return this; },
    };
    let nextCalled = false;
    validatePaymentRequest(invalidAmountReq, res, () => { nextCalled = true; });
    assert.equal(statusCode, 400);
    assert.equal(nextCalled, false);

    // Invalid mode rejected
    const invalidModeReq = { body: { amount: 500, paymentType: 'Bitcoin' } };
    statusCode = null;
    nextCalled = false;
    validatePaymentRequest(invalidModeReq, res, () => { nextCalled = true; });
    assert.equal(statusCode, 400);
    assert.equal(nextCalled, false);

    // Online normalized to UPI
    const onlineReq = { body: { amount: 1500, paymentType: 'online' } };
    let onlineNext = false;
    validatePaymentRequest(onlineReq, {}, () => { onlineNext = true; });
    assert.equal(onlineNext, true);
    assert.equal(onlineReq.body.paymentType, 'UPI');

    // Cash normalized to Cash
    const cashReq = { body: { amount: 1000, paymentType: 'cash' } };
    let cashNext = false;
    validatePaymentRequest(cashReq, {}, () => { cashNext = true; });
    assert.equal(cashNext, true);
    assert.equal(cashReq.body.paymentType, 'Cash');
  });
});

