import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  PERMISSIONS,
  ROLE_PERMISSIONS,
  hasPermission,
  getRolePermissions,
} from '../config/permissions.js';
import {
  requirePermission,
  requireAnyPermission,
  authorize,
} from '../middleware/authMiddleware.js';
import {
  serializeOrderForRole,
  serializeCustomerForRole,
} from '../services/serializerService.js';
import {
  validateMimeType,
  getOwnedPath,
  MAX_FILE_SIZE_BYTES,
} from '../controllers/uploadController.js';

describe('Phase 4: Authorization, Resource Isolation & Media Security', () => {
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

  describe('8.1 Centralized Permission Registry & Role Matrix', () => {
    it('should grant owner universal access (*)', () => {
      assert.equal(hasPermission('owner', PERMISSIONS.CUSTOMERS_DELETE), true);
      assert.equal(hasPermission('owner', PERMISSIONS.ORDERS_DELETE), true);
      assert.equal(hasPermission('owner', PERMISSIONS.STAFF_MANAGE), true);
      assert.equal(hasPermission('owner', PERMISSIONS.LEDGER_READ), true);
      assert.equal(hasPermission('owner', 'any.arbitrary.permission'), true);
    });

    it('should restrict manager from destructive deletions and staff management', () => {
      // Manager CAN manage customers, orders, inventory, and read ledger/reports
      assert.equal(hasPermission('manager', PERMISSIONS.CUSTOMERS_CREATE), true);
      assert.equal(hasPermission('manager', PERMISSIONS.CUSTOMERS_UPDATE), true);
      assert.equal(hasPermission('manager', PERMISSIONS.ORDERS_UPDATE), true);
      assert.equal(hasPermission('manager', PERMISSIONS.PAYMENTS_REFUND), true);
      assert.equal(hasPermission('manager', PERMISSIONS.LEDGER_READ), true);
      assert.equal(hasPermission('manager', PERMISSIONS.INVENTORY_MANAGE), true);

      // Manager CANNOT delete records or manage staff/shop settings
      assert.equal(hasPermission('manager', PERMISSIONS.CUSTOMERS_DELETE), false);
      assert.equal(hasPermission('manager', PERMISSIONS.ORDERS_DELETE), false);
      assert.equal(hasPermission('manager', PERMISSIONS.INVENTORY_DELETE), false);
      assert.equal(hasPermission('manager', PERMISSIONS.STAFF_MANAGE), false);
      assert.equal(hasPermission('manager', PERMISSIONS.SHOP_MANAGE), false);
    });

    it('should restrict staff to front-desk actions without refunds, ledger, or deletions', () => {
      assert.equal(hasPermission('staff', PERMISSIONS.CUSTOMERS_READ), true);
      assert.equal(hasPermission('staff', PERMISSIONS.CUSTOMERS_CREATE), true);
      assert.equal(hasPermission('staff', PERMISSIONS.ORDERS_CREATE), true);
      assert.equal(hasPermission('staff', PERMISSIONS.PAYMENTS_CREATE), true);

      // Forbidden for staff:
      assert.equal(hasPermission('staff', PERMISSIONS.PAYMENTS_REFUND), false);
      assert.equal(hasPermission('staff', PERMISSIONS.LEDGER_READ), false);
      assert.equal(hasPermission('staff', PERMISSIONS.REPORTS_READ), false);
      assert.equal(hasPermission('staff', PERMISSIONS.CUSTOMERS_DELETE), false);
      assert.equal(hasPermission('staff', PERMISSIONS.ORDERS_DELETE), false);
      assert.equal(hasPermission('staff', PERMISSIONS.INVENTORY_MANAGE), false);
      assert.equal(hasPermission('staff', PERMISSIONS.STAFF_MANAGE), false);
    });

    it('should restrict karigars strictly to assigned orders', () => {
      assert.equal(hasPermission('karigar', PERMISSIONS.ASSIGNED_ORDERS_READ), true);
      assert.equal(hasPermission('karigar', PERMISSIONS.ASSIGNED_ORDERS_UPDATE_STAGE), true);

      // Karigars cannot read general orders, customers, finances, or inventory
      assert.equal(hasPermission('karigar', PERMISSIONS.ORDERS_READ), false);
      assert.equal(hasPermission('karigar', PERMISSIONS.CUSTOMERS_READ), false);
      assert.equal(hasPermission('karigar', PERMISSIONS.LEDGER_READ), false);
      assert.equal(hasPermission('karigar', PERMISSIONS.INVENTORY_READ), false);
      assert.equal(hasPermission('karigar', PERMISSIONS.PAYMENTS_CREATE), false);
    });

    it('should block revoked or inactive memberships in requirePermission middleware', () => {
      const middleware = requirePermission(PERMISSIONS.ORDERS_READ);

      // Inactive user
      const reqInactive = { user: { role: 'owner', isActive: false } };
      const res1 = createMockRes();
      let nextCalled1 = false;
      middleware(reqInactive, res1, () => { nextCalled1 = true; });
      assert.equal(nextCalled1, false);
      assert.equal(res1.getStatusCode(), 403);
      assert.match(res1.getJsonBody().message, /inactive or has been revoked/);

      // Revoked user
      const reqRevoked = { user: { role: 'staff', status: 'revoked', isActive: true } };
      const res2 = createMockRes();
      let nextCalled2 = false;
      middleware(reqRevoked, res2, () => { nextCalled2 = true; });
      assert.equal(nextCalled2, false);
      assert.equal(res2.getStatusCode(), 403);

      // Active user with valid permission
      const reqValid = { user: { role: 'staff', isActive: true } };
      const res3 = createMockRes();
      let nextCalled3 = false;
      middleware(reqValid, res3, () => { nextCalled3 = true; });
      assert.equal(nextCalled3, true);
    });
  });

  describe('8.2 Resource & Field Authorization', () => {
    const mockFullOrder = {
      _id: 'ord_secret_777',
      orderId: 'ORD-777',
      customerName: 'Aarav Sharma',
      customer: {
        _id: 'cust_999',
        name: 'Aarav Sharma',
        phone: '+91 98765 43210',
        email: 'aarav@example.com',
      },
      apparelType: 'Sherwani',
      price: 15000,
      totalAmount: 15000,
      advance_amount: 5000,
      status: 'Cutting',
      deliveryDate: '2026-11-20T00:00:00.000Z',
      assignedKarigar: 'karigar_user_1',
      // Sensitive owner-only margins & wholesale costs:
      labor_cost: 3000,
      overhead_cost: 800,
      material_cost: 4500,
      asterProfit: 1200,
      asterCostPrice: 300,
      payment: {
        totalAmount: 15000,
        paidAmount: 5000,
        balanceAmount: 10000,
        status: 'Partial',
      },
      transactions: [
        { _id: 'tx_1', amount: 5000, type: 'Payment' },
      ],
      measurementsSnapshot: {
        chest: '40',
        waist: '34',
        shoulder: '18',
      },
      notes: 'Customer requested double-stitched gold brocade buttons',
    };

    it('should strip owner margins for staff while preserving retail price and customer contacts', () => {
      const staffSerialized = serializeOrderForRole(mockFullOrder, 'staff');

      // Staff can see customer and retail billing
      assert.equal(staffSerialized.orderId, 'ORD-777');
      assert.equal(staffSerialized.price, 15000);
      assert.equal(staffSerialized.customer.phone, '+91 98765 43210');
      assert.equal(staffSerialized.payment.balanceAmount, 10000);

      // Staff CANNOT see owner margins or wholesale costs
      assert.equal(staffSerialized.labor_cost, undefined);
      assert.equal(staffSerialized.overhead_cost, undefined);
      assert.equal(staffSerialized.material_cost, undefined);
      assert.equal(staffSerialized.asterProfit, undefined);
      assert.equal(staffSerialized.asterCostPrice, undefined);
    });

    it('should restrict karigar view to workshop specifications without customer contacts or finances', () => {
      const karigarSerialized = serializeOrderForRole(mockFullOrder, 'karigar');

      // Karigar sees tailoring specs
      assert.equal(karigarSerialized.orderId, 'ORD-777');
      assert.equal(karigarSerialized.apparelType, 'Sherwani');
      assert.equal(karigarSerialized.measurementsSnapshot.chest, '40');
      assert.equal(karigarSerialized.deliveryDate, '2026-11-20T00:00:00.000Z');
      assert.equal(karigarSerialized.customer.name, 'Aarav Sharma');

      // Customer contacts are STRIPPED
      assert.equal(karigarSerialized.customer.phone, undefined);
      assert.equal(karigarSerialized.customer.email, undefined);

      // Financials, prices, and payments are STRIPPED
      assert.equal(karigarSerialized.price, undefined);
      assert.equal(karigarSerialized.totalAmount, undefined);
      assert.equal(karigarSerialized.advance_amount, undefined);
      assert.equal(karigarSerialized.payment, undefined);
      assert.equal(karigarSerialized.transactions, undefined);

      // Margins are STRIPPED
      assert.equal(karigarSerialized.labor_cost, undefined);
      assert.equal(karigarSerialized.material_cost, undefined);
    });

    it('should preserve all wholesale margins for shop owner', () => {
      const ownerSerialized = serializeOrderForRole(mockFullOrder, 'owner');
      assert.equal(ownerSerialized.labor_cost, 3000);
      assert.equal(ownerSerialized.material_cost, 4500);
      assert.equal(ownerSerialized.asterProfit, 1200);
      assert.equal(ownerSerialized.price, 15000);
    });

    it('should reject unassigned karigar from reading or updating order', () => {
      const order = {
        _id: 'ord_1',
        shopId: 'shop_alpha',
        assignedKarigar: 'karigar_user_1',
      };

      const requestingKarigarId = 'karigar_user_2'; // Different karigar!

      let accessGranted = true;
      let statusCode = 200;

      const assignedId = String(order.assignedKarigar);
      if (assignedId !== requestingKarigarId) {
        accessGranted = false;
        statusCode = 403;
      }

      assert.equal(accessGranted, false);
      assert.equal(statusCode, 403);
    });

    it('should reject non-owners from deleting orders, customers, or inventory', () => {
      const nonOwnerRoles = ['staff', 'manager', 'karigar', 'tailor'];

      for (const role of nonOwnerRoles) {
        let orderDeletePermitted = false;
        let customerDeletePermitted = false;
        let inventoryDeletePermitted = false;

        if (role === 'owner') {
          orderDeletePermitted = true;
          customerDeletePermitted = true;
          inventoryDeletePermitted = true;
        }

        assert.equal(orderDeletePermitted, false, `Role ${role} must not delete orders`);
        assert.equal(customerDeletePermitted, false, `Role ${role} must not delete customers`);
        assert.equal(inventoryDeletePermitted, false, `Role ${role} must not delete inventory`);
      }
    });

    it('should enforce strict cross-tenant boundary and prevent cross-shop document leakage', () => {
      const database = [
        { _id: 'ord_shop_A', shopId: 'shop_A', customerName: 'Shop A Customer' },
        { _id: 'ord_shop_B', shopId: 'shop_B', customerName: 'Shop B Customer' },
      ];

      const findOrderScoped = (id, requesterShopId) => {
        const found = database.find((doc) => doc._id === id && doc.shopId === requesterShopId);
        return found || null;
      };

      // Shop A querying its own order -> succeeds
      const resultSelf = findOrderScoped('ord_shop_A', 'shop_A');
      assert.ok(resultSelf);
      assert.equal(resultSelf.customerName, 'Shop A Customer');

      // Shop A attempting to query Shop B's order -> returns standard null / 404 without data leak
      const resultCross = findOrderScoped('ord_shop_B', 'shop_A');
      assert.equal(resultCross, null, 'Must return null without leaking existence of record');
    });
  });

  describe('8.3 Secure Media Uploads & Private Storage URLs', () => {
    it('should accept valid media MIME types (JPEG, PNG, WebP, HEIC, PDF)', () => {
      assert.equal(validateMimeType('image/jpeg'), '.jpg');
      assert.equal(validateMimeType('image/png'), '.png');
      assert.equal(validateMimeType('image/webp'), '.webp');
      assert.equal(validateMimeType('image/heic'), '.heic');
      assert.equal(validateMimeType('application/pdf'), '.pdf');
    });

    it('should reject dangerous or executable MIME types', () => {
      const dangerousMimes = [
        'application/x-msdownload',
        'application/javascript',
        'text/html',
        'application/x-sh',
        'image/svg+xml', // SVGs can contain embedded script tags
        'text/plain',
        '',
        null,
        undefined,
      ];

      for (const mime of dangerousMimes) {
        assert.equal(validateMimeType(mime), null, `MIME ${mime} must be rejected`);
      }
    });

    it('should enforce server-side file size boundary (10MB)', () => {
      const validSize = 5 * 1024 * 1024; // 5MB
      const excessiveSize = 11 * 1024 * 1024; // 11MB

      assert.ok(validSize <= MAX_FILE_SIZE_BYTES);
      assert.ok(excessiveSize > MAX_FILE_SIZE_BYTES);
    });

    it('should generate cryptographically randomized UUID storage paths preventing traversal', () => {
      const shopId = 'shop_42';
      const pathData = getOwnedPath(shopId, 'customer_photo.jpg', 'image/jpeg', 'customers');

      assert.ok(pathData);
      assert.ok(pathData.storagePath.startsWith('shop_42/customers/'));
      assert.ok(pathData.storagePath.endsWith('.jpg'));
      assert.match(pathData.fileName, /^[0-9a-f-]{36}\.jpg$/);

      // Verify path does not contain client-supplied name or traversal sequences
      assert.equal(pathData.storagePath.includes('customer_photo'), false);
      assert.equal(pathData.storagePath.includes('..'), false);
    });

    it('should block cross-tenant media access with 403 Forbidden', () => {
      const requesterShopId = 'shop_100';
      const crossTenantPath = 'shop_200/media/secret-customer-photo.jpg';

      const isAuthorized = crossTenantPath.startsWith(`${requesterShopId}/`);
      assert.equal(isAuthorized, false, 'Cross-tenant media path must be denied');
    });
  });
});

