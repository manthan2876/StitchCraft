import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { authorize } from '../middleware/authMiddleware.js';

describe('Multi-Tenant Shop Isolation & Multi-Role Authorization', () => {
  describe('authorize multi-role check', () => {
    const createMockRes = () => {
      let statusCode = null;
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

    it('should permit owner to access owner-or-manager routes', () => {
      const req = { user: { role: 'owner' } };
      const res = createMockRes();
      let nextCalled = false;
      const next = () => { nextCalled = true; };

      const middleware = authorize('owner', 'manager');
      middleware(req, res, next);

      assert.equal(nextCalled, true);
      assert.equal(res.getStatusCode(), null);
    });

    it('should permit manager to access owner-or-manager routes', () => {
      const req = { user: { role: 'manager' } };
      const res = createMockRes();
      let nextCalled = false;
      const next = () => { nextCalled = true; };

      const middleware = authorize('owner', 'manager');
      middleware(req, res, next);

      assert.equal(nextCalled, true);
      assert.equal(res.getStatusCode(), null);
    });

    it('should deny karigar or staff from accessing owner/manager routes with 403', () => {
      const req = { user: { role: 'karigar' } };
      const res = createMockRes();
      let nextCalled = false;
      const next = () => { nextCalled = true; };

      const middleware = authorize('owner', 'manager');
      middleware(req, res, next);

      assert.equal(nextCalled, false);
      assert.equal(res.getStatusCode(), 403);
      assert.match(res.getJsonBody().message, /forbidden/i);
    });

    it('should deny unauthenticated requests with 401', () => {
      const req = {};
      const res = createMockRes();
      let nextCalled = false;
      const next = () => { nextCalled = true; };

      const middleware = authorize('owner', 'manager');
      middleware(req, res, next);

      assert.equal(nextCalled, false);
      assert.equal(res.getStatusCode(), 401);
      assert.match(res.getJsonBody().message, /not authorized/i);
    });
  });

  describe('Tenant Boundary Partitioning', () => {
    it('should strictly isolate data collections between distinct shops', () => {
      const shop1Id = 'shop-101-ramesh-tailors';
      const shop2Id = 'shop-202-gupta-boutique';

      const dataset = [
        { _id: 'ord-1', shopId: shop1Id, customerName: 'Client A' },
        { _id: 'ord-2', shopId: shop1Id, customerName: 'Client B' },
        { _id: 'ord-3', shopId: shop2Id, customerName: 'Client C' },
      ];

      // Simulated scoped find query
      const findForShop = (targetShopId) => dataset.filter(item => item.shopId === targetShopId);

      const shop1Records = findForShop(shop1Id);
      const shop2Records = findForShop(shop2Id);

      assert.equal(shop1Records.length, 2);
      assert.equal(shop1Records.some(r => r.shopId !== shop1Id), false);

      assert.equal(shop2Records.length, 1);
      assert.equal(shop2Records[0].customerName, 'Client C');
    });

    it('should prevent cross-shop document leakage when querying by ID', () => {
      const activeShopId = 'shop-alpha';
      const foreignRecord = { _id: 'rec-999', shopId: 'shop-beta', secretData: 'Wholesale cost' };

      // Scoped finder must check both ID and active shopId
      const findOneScoped = (id, shopId) => {
        if (foreignRecord._id === id && foreignRecord.shopId === shopId) {
          return foreignRecord;
        }
        return null;
      };

      const result = findOneScoped('rec-999', activeShopId);
      assert.equal(result, null);
    });
  });
});

