/* lib/core/config/sync_registry.dart */

/// Policies governing entity synchronization semantics (Phase 5, 9.1)
enum SyncPolicy {
  versionedRecord,
  versionedChild,
  versionedShopMember,
  immutableEvent,
  transactionalMovement,
}

/// Dynamic registry entry per entity
class SyncRegistryEntry {
  final String entityType;
  final String localTableName;
  final String cloudCollectionName;
  final String primaryKey;
  final String tenantKey;
  final int priority;
  final List<String> dependencies;
  final SyncPolicy policy;
  final List<String> supportedOperations;

  const SyncRegistryEntry({
    required this.entityType,
    required this.localTableName,
    required this.cloudCollectionName,
    required this.primaryKey,
    required this.tenantKey,
    required this.priority,
    required this.dependencies,
    required this.policy,
    required this.supportedOperations,
  });
}

/// Central Sync Registry specifying upload precedence and dependencies (Phase 5, 9.1 & 9.2)
class SyncRegistry {
  static const Map<String, SyncRegistryEntry> registry = {
    'shop': SyncRegistryEntry(
      entityType: 'shop',
      localTableName: 'shop',
      cloudCollectionName: 'shops',
      primaryKey: 'id',
      tenantKey: 'id',
      priority: 1,
      dependencies: [],
      policy: SyncPolicy.versionedRecord,
      supportedOperations: ['read'],
    ),
    'customers': SyncRegistryEntry(
      entityType: 'customers',
      localTableName: 'customers',
      cloudCollectionName: 'customers',
      primaryKey: 'id',
      tenantKey: 'shop_id',
      priority: 2,
      dependencies: ['shop'],
      policy: SyncPolicy.versionedRecord,
      supportedOperations: ['create', 'update', 'delete'],
    ),
    'karigars': SyncRegistryEntry(
      entityType: 'karigars',
      localTableName: 'users',
      cloudCollectionName: 'karigars',
      primaryKey: 'id',
      tenantKey: 'shop_id',
      priority: 2,
      dependencies: ['shop'],
      policy: SyncPolicy.versionedShopMember,
      supportedOperations: ['create', 'update'],
    ),
    'measurements': SyncRegistryEntry(
      entityType: 'measurements',
      localTableName: 'measurements',
      cloudCollectionName: 'measurements',
      primaryKey: 'id',
      tenantKey: 'shop_id',
      priority: 3,
      dependencies: ['customers'],
      policy: SyncPolicy.versionedChild,
      supportedOperations: ['create', 'update'],
    ),
    'inventory': SyncRegistryEntry(
      entityType: 'inventory',
      localTableName: 'inventory',
      cloudCollectionName: 'inventory',
      primaryKey: 'id',
      tenantKey: 'shop_id',
      priority: 3,
      dependencies: ['shop'],
      policy: SyncPolicy.transactionalMovement,
      supportedOperations: ['create', 'update', 'delete'],
    ),
    'orders': SyncRegistryEntry(
      entityType: 'orders',
      localTableName: 'orders',
      cloudCollectionName: 'orders',
      primaryKey: 'id',
      tenantKey: 'shop_id',
      priority: 4,
      dependencies: ['customers', 'karigars', 'measurements', 'inventory'],
      policy: SyncPolicy.versionedRecord,
      supportedOperations: ['create', 'update', 'delete'],
    ),
    'repair_jobs': SyncRegistryEntry(
      entityType: 'repair_jobs',
      localTableName: 'repair_jobs',
      cloudCollectionName: 'repairs',
      primaryKey: 'id',
      tenantKey: 'shop_id',
      priority: 4,
      dependencies: ['customers'],
      policy: SyncPolicy.versionedRecord,
      supportedOperations: ['create', 'update'],
    ),
    'order_payments': SyncRegistryEntry(
      entityType: 'order_payments',
      localTableName: 'order_payments',
      cloudCollectionName: 'transactions',
      primaryKey: 'id',
      tenantKey: 'shop_id',
      priority: 5,
      dependencies: ['orders'],
      policy: SyncPolicy.immutableEvent,
      supportedOperations: ['create', 'payment', 'refund'],
    ),
    'expenses': SyncRegistryEntry(
      entityType: 'expenses',
      localTableName: 'expenses',
      cloudCollectionName: 'ledger_entries',
      primaryKey: 'id',
      tenantKey: 'shop_id',
      priority: 5,
      dependencies: ['shop'],
      policy: SyncPolicy.versionedRecord,
      supportedOperations: ['create', 'update', 'delete'],
    ),
    'inventory_movements': SyncRegistryEntry(
      entityType: 'inventory_movements',
      localTableName: 'inventory_movements',
      cloudCollectionName: 'inventory_movements',
      primaryKey: 'id',
      tenantKey: 'shop_id',
      priority: 6,
      dependencies: ['inventory'],
      policy: SyncPolicy.immutableEvent,
      supportedOperations: ['create', 'movement'],
    ),
  };

  /// Get numerical priority for upload order (1 = highest)
  static int getPriority(String entityType) {
    final entry = registry[entityType.toLowerCase().trim()];
    return entry?.priority ?? 99;
  }

  /// Sort mutations by strict upload order precedence:
  /// Shop -> Customers/Karigars -> Measurements/Inventory -> Orders/Repairs -> Payments/Expenses -> Deliveries/Movements
  static List<Map<String, dynamic>> sortMutations(List<Map<String, dynamic>> mutations) {
    final sorted = List<Map<String, dynamic>>.from(mutations);
    sorted.sort((a, b) {
      final typeA = (a['entity_type'] ?? a['table_name'] ?? '').toString();
      final typeB = (b['entity_type'] ?? b['table_name'] ?? '').toString();
      final pA = getPriority(typeA);
      final pB = getPriority(typeB);
      if (pA != pB) return pA.compareTo(pB);
      final tA = a['created_at']?.toString() ?? '';
      final tB = b['created_at']?.toString() ?? '';
      return tA.compareTo(tB);
    });
    return sorted;
  }
}
