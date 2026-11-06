/**
 * Canonical Synchronization Registry (Phase 5, 9.1)
 * Defines entity policies, upload dependencies, serialization rules,
 * and conflict strategies for complete offline sync coverage.
 */

export const SYNC_POLICIES = {
  VERSIONED_RECORD: 'versioned_record',
  VERSIONED_CHILD: 'versioned_child',
  VERSIONED_SHOP_MEMBER: 'versioned_shop_member',
  IMMUTABLE_EVENT: 'immutable_event',
  TRANSACTIONAL_MOVEMENT: 'transactional_movement',
};

export const SYNC_REGISTRY = {
  shop: {
    entityType: 'shop',
    localTableName: 'shop',
    cloudCollectionName: 'shops',
    primaryKey: 'id',
    tenantKey: 'id',
    priority: 1,
    dependencies: [],
    policy: SYNC_POLICIES.VERSIONED_RECORD,
    supportedOperations: ['read'],
    conflictPolicy: 'server_wins',
  },
  customers: {
    entityType: 'customers',
    localTableName: 'customers',
    cloudCollectionName: 'customers',
    primaryKey: 'id',
    tenantKey: 'shop_id',
    priority: 2,
    dependencies: ['shop'],
    policy: SYNC_POLICIES.VERSIONED_RECORD,
    supportedOperations: ['create', 'update', 'delete'],
    idempotencyStrategy: 'client_mutation_id',
    mediaPolicy: 'upload_first_then_sync',
    conflictPolicy: 'optimistic_version_check',
  },
  karigars: {
    entityType: 'karigars',
    localTableName: 'users',
    cloudCollectionName: 'karigars',
    primaryKey: 'id',
    tenantKey: 'shop_id',
    priority: 2,
    dependencies: ['shop'],
    policy: SYNC_POLICIES.VERSIONED_SHOP_MEMBER,
    supportedOperations: ['create', 'update'],
    conflictPolicy: 'optimistic_version_check',
  },
  measurements: {
    entityType: 'measurements',
    localTableName: 'measurements',
    cloudCollectionName: 'measurements',
    primaryKey: 'id',
    tenantKey: 'shop_id',
    priority: 3,
    dependencies: ['customers'],
    policy: SYNC_POLICIES.VERSIONED_CHILD,
    supportedOperations: ['create', 'update'],
    conflictPolicy: 'optimistic_version_check',
  },
  inventory: {
    entityType: 'inventory',
    localTableName: 'inventory',
    cloudCollectionName: 'inventory',
    primaryKey: 'id',
    tenantKey: 'shop_id',
    priority: 3,
    dependencies: ['shop'],
    policy: SYNC_POLICIES.TRANSACTIONAL_MOVEMENT,
    supportedOperations: ['create', 'update', 'delete'],
    conflictPolicy: 'optimistic_version_check',
  },
  orders: {
    entityType: 'orders',
    localTableName: 'orders',
    cloudCollectionName: 'orders',
    primaryKey: 'id',
    tenantKey: 'shop_id',
    priority: 4,
    dependencies: ['customers', 'karigars', 'measurements', 'inventory'],
    policy: SYNC_POLICIES.VERSIONED_RECORD,
    supportedOperations: ['create', 'update', 'delete'],
    idempotencyStrategy: 'client_mutation_id',
    mediaPolicy: 'upload_first_then_sync',
    conflictPolicy: 'optimistic_version_check',
  },
  repair_jobs: {
    entityType: 'repair_jobs',
    localTableName: 'repair_jobs',
    cloudCollectionName: 'repairs',
    primaryKey: 'id',
    tenantKey: 'shop_id',
    priority: 4,
    dependencies: ['customers'],
    policy: SYNC_POLICIES.VERSIONED_RECORD,
    supportedOperations: ['create', 'update'],
    conflictPolicy: 'optimistic_version_check',
  },
  order_payments: {
    entityType: 'order_payments',
    localTableName: 'order_payments',
    cloudCollectionName: 'transactions',
    primaryKey: 'id',
    tenantKey: 'shop_id',
    priority: 5,
    dependencies: ['orders'],
    policy: SYNC_POLICIES.IMMUTABLE_EVENT,
    supportedOperations: ['create', 'payment', 'refund'],
    idempotencyStrategy: 'client_mutation_id',
    conflictPolicy: 'idempotent_event_deduplication',
  },
  expenses: {
    entityType: 'expenses',
    localTableName: 'expenses',
    cloudCollectionName: 'ledger_entries',
    primaryKey: 'id',
    tenantKey: 'shop_id',
    priority: 5,
    dependencies: ['shop'],
    policy: SYNC_POLICIES.VERSIONED_RECORD,
    supportedOperations: ['create', 'update', 'delete'],
    conflictPolicy: 'optimistic_version_check',
  },
  inventory_movements: {
    entityType: 'inventory_movements',
    localTableName: 'inventory_movements',
    cloudCollectionName: 'inventory_movements',
    primaryKey: 'id',
    tenantKey: 'shop_id',
    priority: 6,
    dependencies: ['inventory'],
    policy: SYNC_POLICIES.IMMUTABLE_EVENT,
    supportedOperations: ['create', 'movement'],
    conflictPolicy: 'append_only_audit_log',
  },
  deliveries: {
    entityType: 'deliveries',
    localTableName: 'orders',
    cloudCollectionName: 'deliveries',
    primaryKey: 'id',
    tenantKey: 'shop_id',
    priority: 6,
    dependencies: ['orders', 'order_payments'],
    policy: SYNC_POLICIES.IMMUTABLE_EVENT,
    supportedOperations: ['create'],
    conflictPolicy: 'explicit_credit_confirmation',
  },
};

/**
 * Get upload priority for an entity type (Phase 5, 9.2)
 * Lower number = higher upload precedence.
 */
export const getUploadPriority = (entityType) => {
  if (!entityType) return 99;
  const key = String(entityType).trim().toLowerCase();
  return SYNC_REGISTRY[key]?.priority ?? 99;
};

/**
 * Sort mutations by strict dependency upload precedence:
 * Shop -> Customers/Karigars -> Measurements/Inventory -> Orders/Repairs -> Payments/Expenses -> Deliveries/Movements
 */
export const sortMutationsByDependency = (mutations = []) => {
  if (!Array.isArray(mutations)) return [];
  return [...mutations].sort((a, b) => {
    const typeA = a.entityType || a.entity_type || a.table_name;
    const typeB = b.entityType || b.entity_type || b.table_name;
    const priorityA = getUploadPriority(typeA);
    const priorityB = getUploadPriority(typeB);
    if (priorityA !== priorityB) {
      return priorityA - priorityB;
    }
    // Secondary sort by timestamp if available
    const timeA = new Date(a.createdAt || a.created_at || 0).getTime();
    const timeB = new Date(b.createdAt || b.created_at || 0).getTime();
    return timeA - timeB;
  });
};

export default {
  SYNC_POLICIES,
  SYNC_REGISTRY,
  getUploadPriority,
  sortMutationsByDependency,
};
