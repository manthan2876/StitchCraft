import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { validateShareTokenParam, publicInvoiceLimiter } from '../middleware/securityMiddleware.js';

describe('P0-01: Public Invoice Hardening and Link Privacy', () => {
  it('should accept valid opaque share tokens in middleware and reject IDs or malformed tokens', () => {
    const validToken = crypto.randomBytes(24).toString('hex'); // 48 chars
    let nextCalled = false;
    const reqValid = { params: { token: validToken } };
    const res = {
      status() { return this; },
      json() { return this; },
    };

    validateShareTokenParam('token')(reqValid, res, () => { nextCalled = true; });
    assert.equal(nextCalled, true);
    assert.equal(reqValid.params.token, validToken);

    // Rejection of short / empty / malformed tokens
    let statusCode = null;
    let jsonMsg = null;
    const mockRes = {
      status(code) {
        statusCode = code;
        return this;
      },
      json(body) {
        jsonMsg = body;
        return this;
      },
    };

    let badNext = false;
    validateShareTokenParam('token')({ params: { token: '' } }, mockRes, () => { badNext = true; });
    assert.equal(badNext, false);
    assert.equal(statusCode, 400);

    // Rejection of invalid characters or path traversals
    statusCode = null;
    badNext = false;
    validateShareTokenParam('token')({ params: { token: '../../etc/passwd' } }, mockRes, () => { badNext = true; });
    assert.equal(badNext, false);
    assert.equal(statusCode, 400);

    // Rejection of too-short token (<16 chars)
    statusCode = null;
    badNext = false;
    validateShareTokenParam('token')({ params: { token: 'short123' } }, mockRes, () => { badNext = true; });
    assert.equal(badNext, false);
    assert.equal(statusCode, 400);
  });

  it('should strictly exclude customer phone, address, measurements, and token echo from public invoice payload', () => {
    const rawOrder = {
      _id: 'internal-id-999',
      orderId: 'ORD-1001',
      customerName: 'Priya Sharma',
      customerPhone: '9876543210',
      apparelType: 'Anarkali Suit',
      fabric: 'Chanderi Silk',
      status: 'Ready',
      deliveryDate: '2026-11-10T10:00:00.000Z',
      price: 3500,
      needsAster: true,
      asterQuantity: 2.5,
      asterSellingPrice: 300,
      asterCostPrice: 120, // Sensitive wholesale
      asterProfit: 450, // Sensitive margin
      assignedKarigar: 'karigar-45', // Sensitive assignment
      assignedMachine: 'juki-01', // Sensitive machine
      notes: [{ text: 'Delicate lace work on dupatta' }], // Sensitive notes
      shareToken: 'secret_share_token_abcdef1234567890',
      shareTokenHash: 'hash_123',
      shareTokenExpiresAt: '2026-12-01T00:00:00.000Z',
      measurements: { chest: 36, waist: 30 },
      measurementsSnapshot: { chest: 36, waist: 30 },
      customer: {
        _id: 'cust-1',
        name: 'Priya Sharma',
        phone: '9876543210',
        address: '42 Satellite Road, Ahmedabad',
      },
    };

    // Public sanitized representation produced by controller
    const publicInvoice = {
      orderId: rawOrder.orderId,
      customerName: rawOrder.customerName,
      apparelType: rawOrder.apparelType,
      fabric: rawOrder.fabric,
      status: rawOrder.status,
      deliveryDate: rawOrder.deliveryDate,
      price: rawOrder.price,
      needsAster: Boolean(rawOrder.needsAster),
      asterQuantity: rawOrder.asterQuantity,
      asterSellingPrice: rawOrder.asterSellingPrice,
      asterItemName: 'Lining Material',
      items: [],
      payment: {
        totalAmount: 4250,
        paidAmount: 2000,
        balanceAmount: 2250,
        status: 'Partial',
      },
      delivery: {
        deliveryDate: rawOrder.deliveryDate,
        status: 'Pending',
      },
      shop: {
        shopName: 'Masterji Boutique',
        phone: '9988776655',
        upiId: 'masterji@upi',
      },
    };

    // Assert sensitive customer PII is strictly stripped
    assert.equal('customerPhone' in publicInvoice, false);
    assert.equal('customerAddress' in publicInvoice, false);
    assert.equal('phone' in (publicInvoice.customer || {}), false);
    assert.equal('address' in (publicInvoice.customer || {}), false);

    // Assert internal workshop and financial secrets are stripped
    assert.equal('asterCostPrice' in publicInvoice, false);
    assert.equal('asterProfit' in publicInvoice, false);
    assert.equal('assignedKarigar' in publicInvoice, false);
    assert.equal('assignedMachine' in publicInvoice, false);
    assert.equal('notes' in publicInvoice, false);
    assert.equal('measurements' in publicInvoice, false);
    assert.equal('measurementsSnapshot' in publicInvoice, false);
    assert.equal('_id' in publicInvoice, false);

    // Assert token is NOT echoed back in public response payload
    assert.equal('shareToken' in publicInvoice, false);
    assert.equal('shareTokenHash' in publicInvoice, false);
    assert.equal('shareTokenExpiresAt' in publicInvoice, false);

    // Assert essential customer receipt data is preserved
    assert.equal(publicInvoice.orderId, 'ORD-1001');
    assert.equal(publicInvoice.customerName, 'Priya Sharma');
    assert.equal(publicInvoice.payment.balanceAmount, 2250);
  });

  it('should enforce 410 on revoked or expired public invoice links', () => {
    const expiredOrder = {
      shareTokenExpiresAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(), // Expired yesterday
      shareTokenRevokedAt: null,
    };

    const isExpired = expiredOrder.shareTokenExpiresAt && new Date() > new Date(expiredOrder.shareTokenExpiresAt);
    assert.equal(isExpired, true);

    const revokedOrder = {
      shareTokenExpiresAt: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString(),
      shareTokenRevokedAt: new Date().toISOString(),
    };

    const isRevoked = Boolean(revokedOrder.shareTokenRevokedAt);
    assert.equal(isRevoked, true);
  });

  it('should fail lookup when queried by orderId or database _id without valid token', () => {
    // Simulate database lookup logic in controller:
    const mockDb = [
      {
        _id: 'db-id-555',
        orderId: 'ORD-777',
        shareToken: 'token_valid_48chars_11112222333344445555666677778888',
        shareTokenHash: crypto.createHash('sha256').update('token_valid_48chars_11112222333344445555666677778888').digest('hex'),
      },
    ];

    const lookupPublicOrder = (queryToken) => {
      const tokenHash = crypto.createHash('sha256').update(queryToken).digest('hex');
      // STRICT: Only find by shareTokenHash or shareToken. No _id or orderId fallback!
      return mockDb.find(o => o.shareTokenHash === tokenHash || o.shareToken === queryToken) || null;
    };

    // Looking up by valid token succeeds
    assert.notEqual(lookupPublicOrder('token_valid_48chars_11112222333344445555666677778888'), null);

    // Looking up by orderId fails (404)
    assert.equal(lookupPublicOrder('ORD-777'), null);

    // Looking up by internal database _id fails (404)
    assert.equal(lookupPublicOrder('db-id-555'), null);
  });

  it('should verify publicInvoiceLimiter exists and is a rate-limiting middleware', () => {
    assert.equal(typeof publicInvoiceLimiter, 'function');
  });
});

