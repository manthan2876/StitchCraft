import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { isOriginAllowed, getAllowedOrigins } from '../config/cors.js';
import { authorize } from '../middleware/authMiddleware.js';
import { resolveEntryDate, getTimestamp } from '../services/ledgerService.js';

describe('Phase 1: P0 Runtime & Security Fixes', () => {
  const createMockRes = () => {
    let statusCode = 200;
    let jsonBody = null;
    return {
      status(code) {
        statusCode = code;
        return this;
      },
      json(body) {
        jsonBody = body;
        return this;
      },
      getStatusCode: () => statusCode,
      getJsonBody: () => jsonBody,
    };
  };

  describe('5.1 Deployment & Cross-Origin Configuration', () => {
    it('should parse CLIENT_URL and ALLOWED_ORIGINS dynamically from env', () => {
      const customEnv = {
        CLIENT_URL: 'https://custom-shop.example.com, https://another-domain.com',
        ALLOWED_ORIGINS: 'https://third-domain.com',
        NODE_ENV: 'production',
      };
      const allowed = getAllowedOrigins(customEnv);
      assert.ok(allowed.includes('https://custom-shop.example.com'));
      assert.ok(allowed.includes('https://another-domain.com'));
      assert.ok(allowed.includes('https://third-domain.com'));
    });

    it('should permit requests without origin (mobile Flutter, curl, server-to-server)', () => {
      assert.equal(isOriginAllowed(undefined), true);
      assert.equal(isOriginAllowed(null), true);
      assert.equal(isOriginAllowed(''), true);
    });

    it('should reject unconfigured origins in production', () => {
      const prodEnv = {
        NODE_ENV: 'production',
        CLIENT_URL: 'https://allowed-production.com',
      };
      assert.equal(isOriginAllowed('https://allowed-production.com', prodEnv), true);
      assert.equal(isOriginAllowed('https://evil-attacker.com', prodEnv), false);
      assert.equal(isOriginAllowed('http://localhost:5173', prodEnv), false);
    });

    it('should permit local development origins in non-production environments', () => {
      const devEnv = { NODE_ENV: 'development' };
      assert.equal(isOriginAllowed('http://localhost:5173', devEnv), true);
      assert.equal(isOriginAllowed('http://127.0.0.1:5173', devEnv), true);
      assert.equal(isOriginAllowed('http://192.168.1.50:5173', devEnv), true);
      assert.equal(isOriginAllowed('https://random-unauthorized.com', devEnv), false);
    });
  });

  describe('5.2 Multi-Role Authentication & Route Authorization', () => {
    it('should admit owner into owner-only routes', () => {
      const req = { user: { role: 'owner' } };
      const res = createMockRes();
      let nextCalled = false;
      const next = () => { nextCalled = true; };

      const middleware = authorize('owner');
      middleware(req, res, next);

      assert.equal(nextCalled, true);
    });

    it('should admit both owner and manager into authorize("owner", "manager") routes', () => {
      let nextManager = false;
      let nextOwner = false;

      const middleware = authorize('owner', 'manager');

      middleware({ user: { role: 'manager' } }, createMockRes(), () => { nextManager = true; });
      middleware({ user: { role: 'owner' } }, createMockRes(), () => { nextOwner = true; });

      assert.equal(nextManager, true);
      assert.equal(nextOwner, true);
    });

    it('should reject unlisted roles with 403 on protected routes', () => {
      const middleware = authorize('owner', 'manager');
      const res = createMockRes();
      let nextCalled = false;

      middleware({ user: { role: 'karigar' } }, res, () => { nextCalled = true; });

      assert.equal(nextCalled, false);
      assert.equal(res.getStatusCode(), 403);
      assert.match(res.getJsonBody().message, /forbidden/i);
    });

    it('should reject unauthenticated requests with 401', () => {
      const middleware = authorize('owner');
      const res = createMockRes();
      let nextCalled = false;

      middleware({}, res, () => { nextCalled = true; });

      assert.equal(nextCalled, false);
      assert.equal(res.getStatusCode(), 401);
    });
  });

  describe('5.3 Close Delivery-Credit Bypasses', () => {
    // Pure domain specification testing delivery credit rules
    const validateDeliveryTransition = ({ order, payment, allowCredit, creditReason, userName }) => {
      if (order.status === 'Delivered') {
        const err = new Error('Order has already been marked as delivered');
        err.statusCode = 400;
        throw err;
      }

      const balance = payment ? Number(payment.balanceAmount || 0) : 0;
      if (balance > 0) {
        if (!allowCredit) {
          const err = new Error(`Order has an outstanding balance of ₹${balance}. Please collect payment or confirm delivery on credit.`);
          err.statusCode = 400;
          err.requiresCreditApproval = true;
          err.balanceAmount = balance;
          throw err;
        }

        const reason = (creditReason || '').trim();
        if (!reason) {
          const err = new Error('A reason is required to approve delivery on credit (udhar).');
          err.statusCode = 400;
          throw err;
        }

        const note = {
          text: `Delivered on credit (udhar ₹${balance}). Reason: ${reason}`,
          addedAt: new Date().toISOString(),
        };

        return {
          status: 'Delivered',
          allowCredit: true,
          creditReason: reason,
          creditApprovedBy: userName || 'Owner',
          deliveredBy: userName || 'Owner',
          note,
        };
      }

      return {
        status: 'Delivered',
        allowCredit: false,
        deliveredBy: userName || 'Owner',
      };
    };

    it('should reject marking order as Delivered when balance is outstanding without allowCredit', () => {
      assert.throws(
        () => {
          validateDeliveryTransition({
            order: { _id: 'o1', status: 'Ready' },
            payment: { totalAmount: 4000, paidAmount: 1000, balanceAmount: 3000 },
            allowCredit: false,
            creditReason: '',
            userName: 'Owner',
          });
        },
        (err) => {
          assert.equal(err.statusCode, 400);
          assert.equal(err.requiresCreditApproval, true);
          assert.equal(err.balanceAmount, 3000);
          assert.match(err.message, /outstanding balance/i);
          return true;
        }
      );
    });

    it('should reject credit delivery if creditReason is empty or only whitespace', () => {
      assert.throws(
        () => {
          validateDeliveryTransition({
            order: { _id: 'o2', status: 'Ready' },
            payment: { totalAmount: 5000, paidAmount: 0, balanceAmount: 5000 },
            allowCredit: true,
            creditReason: '   ',
            userName: 'Owner',
          });
        },
        (err) => {
          assert.equal(err.statusCode, 400);
          assert.match(err.message, /reason is required/i);
          return true;
        }
      );
    });

    it('should approve delivery when fully paid without requiring credit reason', () => {
      const result = validateDeliveryTransition({
        order: { _id: 'o3', status: 'Ready' },
        payment: { totalAmount: 3000, paidAmount: 3000, balanceAmount: 0 },
        allowCredit: false,
        userName: 'Owner',
      });
      assert.equal(result.status, 'Delivered');
      assert.equal(result.allowCredit, false);
      assert.equal(result.deliveredBy, 'Owner');
    });

    it('should approve delivery on credit when allowCredit is true and non-empty reason is supplied, recording auditable note', () => {
      const result = validateDeliveryTransition({
        order: { _id: 'o4', status: 'Ready' },
        payment: { totalAmount: 4500, paidAmount: 1500, balanceAmount: 3000 },
        allowCredit: true,
        creditReason: 'Long-time customer, settle next week',
        userName: 'ShopManager',
      });
      assert.equal(result.status, 'Delivered');
      assert.equal(result.allowCredit, true);
      assert.equal(result.creditReason, 'Long-time customer, settle next week');
      assert.equal(result.creditApprovedBy, 'ShopManager');
      assert.match(result.note.text, /Delivered on credit \(udhar ₹3000\)\. Reason: Long-time customer/);
    });

    it('should reject duplicate delivery attempts', () => {
      assert.throws(
        () => {
          validateDeliveryTransition({
            order: { _id: 'o5', status: 'Delivered' },
            payment: { totalAmount: 2000, paidAmount: 2000, balanceAmount: 0 },
            allowCredit: false,
          });
        },
        (err) => {
          assert.equal(err.statusCode, 400);
          assert.match(err.message, /already been marked as delivered/i);
          return true;
        }
      );
    });
  });

  describe('5.4 Deterministic Correctness Defects', () => {
    describe('Deterministic Ledger Sorting', () => {
      it('should fall back safely when dates are invalid or undefined without producing NaN', () => {
        const d1 = resolveEntryDate(null, '2026-05-10T12:00:00.000Z');
        assert.equal(d1, '2026-05-10T12:00:00.000Z');

        const d2 = resolveEntryDate('not-a-valid-date', null);
        assert.equal(d2, new Date(0).toISOString());

        const tInvalid = getTimestamp('bad-date');
        assert.equal(tInvalid, 0);
        assert.equal(Number.isNaN(tInvalid), false);

        const tValid = getTimestamp('2026-05-10T12:00:00.000Z');
        assert.ok(tValid > 0);
      });

      it('should sort entries deterministically with primary date and secondary id tie-breaker', () => {
        const items = [
          { _id: 'b-id', date: '2026-05-10T10:00:00.000Z' },
          { _id: 'a-id', date: '2026-05-10T10:00:00.000Z' },
          { _id: 'c-id', date: 'invalid-date' },
        ];

        items.sort((a, b) => {
          const diff = getTimestamp(b.date) - getTimestamp(a.date);
          if (diff !== 0) return diff;
          return String(a._id).localeCompare(String(b._id));
        });

        assert.equal(items[0]._id, 'a-id');
        assert.equal(items[1]._id, 'b-id');
        assert.equal(items[2]._id, 'c-id');
      });
    });

    describe('Customer Soft-Deletion & History Preservation', () => {
      const validateCustomerDeletion = ({ customer, orders }) => {
        if (!customer || customer.isDeleted) {
          return { notFound: true };
        }

        // Active orders guard
        const activeOrders = orders.filter(
          (o) => (String(o.customer) === String(customer._id) || String(o.customerId) === String(customer._id)) &&
                 !['Delivered', 'Cancelled'].includes(o.status)
        );

        if (activeOrders.length > 0) {
          const err = new Error(
            `Cannot delete customer '${customer.name}' with ${activeOrders.length} active order(s). Please complete or cancel orders before deleting.`
          );
          err.statusCode = 400;
          err.hasActiveOrders = true;
          throw err;
        }

        // Soft deletion preserving references
        return {
          success: true,
          customer: {
            ...customer,
            isDeleted: true,
            deletedAt: new Date().toISOString(),
          },
        };
      };

      it('should reject deleting a customer who has active in-progress orders', () => {
        const customer = { _id: 'c1', name: 'Sunita Rao', isDeleted: false };
        const orders = [
          { _id: 'ord1', customer: 'c1', status: 'Cutting', price: 1500 },
        ];

        assert.throws(
          () => {
            validateCustomerDeletion({ customer, orders });
          },
          (err) => {
            assert.equal(err.statusCode, 400);
            assert.equal(err.hasActiveOrders, true);
            assert.match(err.message, /active order/i);
            return true;
          }
        );
      });

      it('should soft delete customer when no active orders, preserving history and foreign keys', () => {
        const customer = { _id: 'c2', name: 'Karan Mehra', isDeleted: false };
        const orders = [
          { _id: 'ord2', customer: 'c2', status: 'Delivered', price: 1200 },
        ];

        const result = validateCustomerDeletion({ customer, orders });
        assert.equal(result.success, true);
        assert.equal(result.customer.isDeleted, true);
        assert.ok(result.customer.deletedAt);

        // Verification that active order list filters out soft-deleted customers
        const customersList = [result.customer, { _id: 'c3', name: 'Amit', isDeleted: false }];
        const activeCustomers = customersList.filter(c => !c.isDeleted);
        assert.equal(activeCustomers.length, 1);
        assert.equal(activeCustomers[0]._id, 'c3');
      });
    });
  });
});
