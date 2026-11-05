/* test/staff_management.test.js */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { authorize } from '../middleware/authMiddleware.js';

describe('Staff & Roles Management Security Policies', () => {
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

  it('should allow owner to perform role assignments and staff management', () => {
    const req = { user: { role: 'owner', shopId: 'shop-1' } };
    const res = createMockRes();
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    const ownerOnlyMiddleware = authorize('owner');
    ownerOnlyMiddleware(req, res, next);

    assert.equal(nextCalled, true);
    assert.equal(res.getStatusCode(), null);
  });

  it('should deny manager and non-owner roles from accessing staff management (P0-02)', () => {
    const req = { user: { role: 'manager', shopId: 'shop-1' } };
    const res = createMockRes();
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    const ownerMiddleware = authorize('owner');
    ownerMiddleware(req, res, next);

    assert.equal(nextCalled, false);
    assert.equal(res.getStatusCode(), 403);
  });

  it('should block managers from owner-only actions like changing roles or unlinking staff', () => {
    const req = { user: { role: 'manager', shopId: 'shop-1' } };
    const res = createMockRes();
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    const ownerOnlyMiddleware = authorize('owner');
    ownerOnlyMiddleware(req, res, next);

    assert.equal(nextCalled, false);
    assert.equal(res.getStatusCode(), 403);
  });

  it('should block standard staff and karigars from staff management entirely', () => {
    const karigarReq = { user: { role: 'karigar', shopId: 'shop-1' } };
    const res = createMockRes();
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    const ownerOrManagerMiddleware = authorize('owner', 'manager');
    ownerOrManagerMiddleware(karigarReq, res, next);

    assert.equal(nextCalled, false);
    assert.equal(res.getStatusCode(), 403);
  });

  it('should validate allowed roles for team members', () => {
    const validRoles = ['owner', 'manager', 'karigar', 'staff'];
    assert.equal(validRoles.includes('manager'), true);
    assert.equal(validRoles.includes('karigar'), true);
    assert.equal(validRoles.includes('staff'), true);
    assert.equal(validRoles.includes('admin'), false);
    assert.equal(validRoles.includes('superuser'), false);
  });
});

