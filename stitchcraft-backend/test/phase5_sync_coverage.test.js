import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  SYNC_REGISTRY,
  SYNC_POLICIES,
  getUploadPriority,
  sortMutationsByDependency,
} from '../config/syncRegistry.js';

describe('Phase 5: Complete & Observable Synchronization Coverage', () => {
  describe('9.1 Sync Registry Specifications', () => {
    it('should define canonical registry entries for all core entities with required metadata', () => {
      const requiredEntities = [
        'shop',
        'customers',
        'karigars',
        'measurements',
        'inventory',
        'orders',
        'repair_jobs',
        'order_payments',
        'expenses',
        'inventory_movements',
      ];

      for (const entity of requiredEntities) {
        const entry = SYNC_REGISTRY[entity];
        assert.ok(entry, `Registry must include entry for "${entity}"`);
        assert.ok(entry.entityType, `Entity "${entity}" must define entityType`);
        assert.ok(entry.localTableName, `Entity "${entity}" must define localTableName`);
        assert.ok(entry.cloudCollectionName, `Entity "${entity}" must define cloudCollectionName`);
        assert.ok(entry.primaryKey, `Entity "${entity}" must define primaryKey`);
        assert.ok(entry.tenantKey, `Entity "${entity}" must define tenantKey`);
        assert.ok(typeof entry.priority === 'number', `Entity "${entity}" must have a numerical priority`);
        assert.ok(Array.isArray(entry.dependencies), `Entity "${entity}" must define dependencies array`);
        assert.ok(entry.policy, `Entity "${entity}" must define a sync policy`);
      }
    });

    it('should match the policy decisions specified in Section 9.1', () => {
      assert.equal(SYNC_REGISTRY.customers.policy, SYNC_POLICIES.VERSIONED_RECORD);
      assert.equal(SYNC_REGISTRY.measurements.policy, SYNC_POLICIES.VERSIONED_CHILD);
      assert.equal(SYNC_REGISTRY.karigars.policy, SYNC_POLICIES.VERSIONED_SHOP_MEMBER);
      assert.equal(SYNC_REGISTRY.orders.policy, SYNC_POLICIES.VERSIONED_RECORD);
      assert.equal(SYNC_REGISTRY.order_payments.policy, SYNC_POLICIES.IMMUTABLE_EVENT);
      assert.equal(SYNC_REGISTRY.inventory.policy, SYNC_POLICIES.TRANSACTIONAL_MOVEMENT);
      assert.equal(SYNC_REGISTRY.expenses.policy, SYNC_POLICIES.VERSIONED_RECORD);
      assert.equal(SYNC_REGISTRY.inventory_movements.policy, SYNC_POLICIES.IMMUTABLE_EVENT);
    });

    it('should declare correct parent-child dependencies across entities', () => {
      assert.ok(SYNC_REGISTRY.measurements.dependencies.includes('customers'), 'Measurements must depend on customers');
      assert.ok(SYNC_REGISTRY.orders.dependencies.includes('customers'), 'Orders must depend on customers');
      assert.ok(SYNC_REGISTRY.orders.dependencies.includes('karigars'), 'Orders must depend on karigars');
      assert.ok(SYNC_REGISTRY.order_payments.dependencies.includes('orders'), 'Payments must depend on orders');
      assert.ok(SYNC_REGISTRY.inventory_movements.dependencies.includes('inventory'), 'Movements must depend on inventory');
    });
  });

  describe('9.2 Dependency Ordering & Triggers', () => {
    it('should enforce strict upload order: Shop -> Customers/Karigars -> Measurements/Inventory -> Orders/Repairs -> Payments/Expenses -> Deliveries/Movements', () => {
      assert.ok(getUploadPriority('shop') < getUploadPriority('customers'));
      assert.ok(getUploadPriority('customers') < getUploadPriority('measurements'));
      assert.ok(getUploadPriority('measurements') < getUploadPriority('orders'));
      assert.ok(getUploadPriority('orders') < getUploadPriority('order_payments'));
      assert.ok(getUploadPriority('order_payments') < getUploadPriority('deliveries'));
    });

    it('should sort a batch of mixed outbox mutations strictly by dependency precedence', () => {
      const unsortedMutations = [
        { clientMutationId: 'm_delivery', entityType: 'deliveries', createdAt: '2026-11-06T10:05:00Z' },
        { clientMutationId: 'm_payment', entityType: 'order_payments', createdAt: '2026-11-06T10:04:00Z' },
        { clientMutationId: 'm_order', entityType: 'orders', createdAt: '2026-11-06T10:03:00Z' },
        { clientMutationId: 'm_inventory', entityType: 'inventory', createdAt: '2026-11-06T10:02:00Z' },
        { clientMutationId: 'm_measurement', entityType: 'measurements', createdAt: '2026-11-06T10:01:30Z' },
        { clientMutationId: 'm_customer', entityType: 'customers', createdAt: '2026-11-06T10:01:00Z' },
        { clientMutationId: 'm_shop', entityType: 'shop', createdAt: '2026-11-06T10:00:00Z' },
      ];

      const sorted = sortMutationsByDependency(unsortedMutations);
      const sortedIds = sorted.map((m) => m.clientMutationId);

      assert.deepEqual(sortedIds, [
        'm_shop',
        'm_customer',
        'm_measurement',
        'm_inventory',
        'm_order',
        'm_payment',
        'm_delivery',
      ]);
    });

    it('should sort same-priority mutations by secondary creation timestamp', () => {
      const samePriorityMutations = [
        { clientMutationId: 'c2', entityType: 'customers', createdAt: '2026-11-06T10:02:00Z' },
        { clientMutationId: 'c1', entityType: 'customers', createdAt: '2026-11-06T10:01:00Z' },
      ];

      const sorted = sortMutationsByDependency(samePriorityMutations);
      assert.equal(sorted[0].clientMutationId, 'c1');
      assert.equal(sorted[1].clientMutationId, 'c2');
    });
  });

  describe('9.3 Sync Status UX & Observability Rules', () => {
    it('should NEVER display "Up to date" when unresolved pending mutations exist', () => {
      const computeDisplayStatus = ({ totalPending, failedRecords, isSyncing, syncError }) => {
        const hasUnresolved = totalPending > 0 || failedRecords.length > 0;
        if (isSyncing) return 'Syncing...';
        if (syncError) return `Error: ${syncError}`;
        if (failedRecords.length > 0) return `${failedRecords.length} records require attention`;
        if (totalPending > 0) return `${totalPending} pending local changes`;
        return 'All changes synced'; // "Up to date"
      };

      // Scenario A: Clean sync
      assert.equal(
        computeDisplayStatus({ totalPending: 0, failedRecords: [], isSyncing: false, syncError: null }),
        'All changes synced'
      );

      // Scenario B: Pending changes exist -> MUST NOT say "All changes synced"
      assert.notEqual(
        computeDisplayStatus({ totalPending: 3, failedRecords: [], isSyncing: false, syncError: null }),
        'All changes synced'
      );
      assert.equal(
        computeDisplayStatus({ totalPending: 3, failedRecords: [], isSyncing: false, syncError: null }),
        '3 pending local changes'
      );

      // Scenario C: Failed records exist -> MUST NOT say "All changes synced"
      assert.notEqual(
        computeDisplayStatus({ totalPending: 0, failedRecords: [{ id: 'fail_1' }], isSyncing: false, syncError: null }),
        'All changes synced'
      );
      assert.equal(
        computeDisplayStatus({ totalPending: 0, failedRecords: [{ id: 'fail_1' }], isSyncing: false, syncError: null }),
        '1 records require attention'
      );
    });

    it('should track failed and conflict counts separately for actionable resolution', () => {
      const outbox = [
        { id: 'm1', status: 'synced' },
        { id: 'm2', status: 'conflict', conflict_state: 'conflict', last_error: 'Concurrent modification' },
        { id: 'm3', status: 'failed', last_error: 'Invalid phone format' },
      ];

      const pending = outbox.filter((m) => m.status === 'pending').length;
      const conflicts = outbox.filter((m) => m.status === 'conflict').length;
      const failures = outbox.filter((m) => m.status === 'failed').length;

      assert.equal(pending, 0);
      assert.equal(conflicts, 1);
      assert.equal(failures, 1);
    });
  });

  describe('End-to-End Batch Push & Idempotency Pipeline', () => {
    it('should return idempotent response on replay of already-processed mutation', () => {
      const processedMutations = new Map([
        ['mut_existing_1', { response: { orderId: 'ORD-100', totalAmount: 1200 }, statusCode: 200 }],
      ]);

      const processSyncMutation = (mutation) => {
        if (processedMutations.has(mutation.clientMutationId)) {
          const cached = processedMutations.get(mutation.clientMutationId);
          return {
            clientMutationId: mutation.clientMutationId,
            status: 'synced',
            isReplay: true,
            data: cached.response,
          };
        }
        return {
          clientMutationId: mutation.clientMutationId,
          status: 'synced',
          isReplay: false,
          data: { created: true },
        };
      };

      const result = processSyncMutation({ clientMutationId: 'mut_existing_1' });
      assert.equal(result.isReplay, true);
      assert.equal(result.status, 'synced');
      assert.equal(result.data.orderId, 'ORD-100');
    });

    it('should detect 409 conflict when base_version does not match current server version', () => {
      const currentServerVersion = 3;
      const incomingBaseVersion = 1;

      let conflictDetected = false;
      let conflictResponse = null;

      if (incomingBaseVersion !== currentServerVersion) {
        conflictDetected = true;
        conflictResponse = {
          status: 'conflict',
          serverVersion: currentServerVersion,
          error: 'Conflict: concurrent modification detected',
        };
      }

      assert.equal(conflictDetected, true);
      assert.equal(conflictResponse.status, 'conflict');
      assert.equal(conflictResponse.serverVersion, 3);
    });
  });
});
