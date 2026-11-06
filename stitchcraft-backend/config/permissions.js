/**
 * Centralized Permission Registry (Phase 4, 8.1)
 * Defines canonical permissions, role mappings, and authorization helpers.
 */

export const PERMISSIONS = {
  // Shop & Settings
  SHOP_READ: 'shop.read',
  SHOP_MANAGE: 'shop.manage',

  // Staff Management (Owner-only)
  STAFF_READ: 'staff.read',
  STAFF_MANAGE: 'staff.manage',

  // Customers
  CUSTOMERS_READ: 'customers.read',
  CUSTOMERS_CREATE: 'customers.create',
  CUSTOMERS_UPDATE: 'customers.update',
  CUSTOMERS_DELETE: 'customers.delete',

  // Orders
  ORDERS_READ: 'orders.read',
  ORDERS_CREATE: 'orders.create',
  ORDERS_UPDATE: 'orders.update',
  ORDERS_DELETE: 'orders.delete',

  // Payments & Refunds
  PAYMENTS_READ: 'payments.read',
  PAYMENTS_CREATE: 'payments.create',
  PAYMENTS_REFUND: 'payments.refund',

  // Financial Ledger & Reports
  LEDGER_READ: 'ledger.read',
  REPORTS_READ: 'reports.read',

  // Inventory
  INVENTORY_READ: 'inventory.read',
  INVENTORY_MANAGE: 'inventory.manage',
  INVENTORY_DELETE: 'inventory.delete',

  // Assigned Orders (Karigar / Tailor)
  ASSIGNED_ORDERS_READ: 'assigned_orders.read',
  ASSIGNED_ORDERS_UPDATE_STAGE: 'assigned_orders.update_stage',

  // Media Storage
  MEDIA_UPLOAD: 'media.upload',
  MEDIA_VIEW: 'media.view',
  MEDIA_DELETE: 'media.delete',
};

/**
 * Role-to-Permission Mapping Matrix (Phase 4, 8.1)
 */
export const ROLE_PERMISSIONS = {
  // Owner: Full unrestricted access across all tenant resources
  owner: ['*'],

  // Manager: Operational administration without destructive deletions or owner-level settings
  manager: [
    PERMISSIONS.SHOP_READ,
    PERMISSIONS.STAFF_READ,
    PERMISSIONS.CUSTOMERS_READ,
    PERMISSIONS.CUSTOMERS_CREATE,
    PERMISSIONS.CUSTOMERS_UPDATE,
    PERMISSIONS.ORDERS_READ,
    PERMISSIONS.ORDERS_CREATE,
    PERMISSIONS.ORDERS_UPDATE,
    PERMISSIONS.PAYMENTS_READ,
    PERMISSIONS.PAYMENTS_CREATE,
    PERMISSIONS.PAYMENTS_REFUND,
    PERMISSIONS.LEDGER_READ,
    PERMISSIONS.REPORTS_READ,
    PERMISSIONS.INVENTORY_READ,
    PERMISSIONS.INVENTORY_MANAGE,
    PERMISSIONS.ASSIGNED_ORDERS_READ,
    PERMISSIONS.ASSIGNED_ORDERS_UPDATE_STAGE,
    PERMISSIONS.MEDIA_UPLOAD,
    PERMISSIONS.MEDIA_VIEW,
  ],

  // Staff / Sales: Day-to-day front desk and order entry. Cannot delete, refund, view margins or ledger.
  staff: [
    PERMISSIONS.SHOP_READ,
    PERMISSIONS.CUSTOMERS_READ,
    PERMISSIONS.CUSTOMERS_CREATE,
    PERMISSIONS.CUSTOMERS_UPDATE,
    PERMISSIONS.ORDERS_READ,
    PERMISSIONS.ORDERS_CREATE,
    PERMISSIONS.ORDERS_UPDATE,
    PERMISSIONS.PAYMENTS_READ,
    PERMISSIONS.PAYMENTS_CREATE,
    PERMISSIONS.INVENTORY_READ,
    PERMISSIONS.ASSIGNED_ORDERS_READ,
    PERMISSIONS.MEDIA_UPLOAD,
    PERMISSIONS.MEDIA_VIEW,
  ],

  // Karigar / Tailor: Workshop execution. Strictly assigned jobs, styling & measurements only.
  karigar: [
    PERMISSIONS.ASSIGNED_ORDERS_READ,
    PERMISSIONS.ASSIGNED_ORDERS_UPDATE_STAGE,
    PERMISSIONS.MEDIA_VIEW,
  ],

  // Tailor alias for Karigar
  tailor: [
    PERMISSIONS.ASSIGNED_ORDERS_READ,
    PERMISSIONS.ASSIGNED_ORDERS_UPDATE_STAGE,
    PERMISSIONS.MEDIA_VIEW,
  ],
};

/**
 * Check whether a given user role possesses a specific permission
 */
export const hasPermission = (userRole, permission) => {
  if (!userRole || typeof userRole !== 'string') return false;
  const role = userRole.trim().toLowerCase();
  const permissions = ROLE_PERMISSIONS[role] || [];
  if (permissions.includes('*')) return true;
  return permissions.includes(permission);
};

/**
 * Retrieve all effective permissions for a role
 */
export const getRolePermissions = (userRole) => {
  if (!userRole || typeof userRole !== 'string') return [];
  const role = userRole.trim().toLowerCase();
  return ROLE_PERMISSIONS[role] || [];
};

export default {
  PERMISSIONS,
  ROLE_PERMISSIONS,
  hasPermission,
  getRolePermissions,
};

