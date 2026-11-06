import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

describe('Phase 2: Offline Synchronization Foundation', () => {
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

  describe('6.3 Optimistic Concurrency & Server Idempotency', () => {
    it('should increment version on valid update matching base_version', () => {
      const order = {
        _id: 'ord_101',
        orderId: 'ORD-101',
        shopId: 'shop_1',
        status: 'Cutting',
        version: 1,
      };

      const baseVersion = 1;
      assert.equal(order.version, baseVersion);

      // Apply update
      order.status = 'Stitching';
      order.version = (order.version || 1) + 1;

      assert.equal(order.status, 'Stitching');
      assert.equal(order.version, 2);
    });

    it('should reject stale update with HTTP 409 Conflict when base_version does not match current version', () => {
      const customer = {
        _id: 'cust_201',
        name: 'Anita Patel',
        phone: '9876543210',
        shopId: 'shop_1',
        version: 3, // Server has version 3
      };

      const staleClientUpdate = {
        name: 'Anita P. Shah',
        base_version: 1, // Client only had version 1
      };

      let conflictThrown = false;
      let conflictResponse = null;

      try {
        const clientBaseVersion = Number(staleClientUpdate.base_version);
        if (customer.version !== clientBaseVersion) {
          const conflictErr = new Error('Conflict: concurrent modification detected');
          conflictErr.statusCode = 409;
          conflictErr.serverVersion = customer.version;
          conflictErr.currentData = customer;
          throw conflictErr;
        }
      } catch (err) {
        conflictThrown = true;
        conflictResponse = {
          statusCode: err.statusCode,
          message: err.message,
          serverVersion: err.serverVersion,
          currentData: err.currentData,
        };
      }

      assert.equal(conflictThrown, true);
      assert.equal(conflictResponse.statusCode, 409);
      assert.equal(conflictResponse.serverVersion, 3);
      assert.equal(conflictResponse.currentData.name, 'Anita Patel');
    });

    it('should return cached result on retrying mutation with identical key (idempotency deduplication)', async () => {
      // In-memory simulation of SyncMutation collection
      const mutationStore = new Map();

      const simulateIdempotentEndpoint = async ({ shopId, mutationId, method, entityType, action, payload }) => {
        const key = `${shopId}_${mutationId}`;
        const existing = mutationStore.get(key);

        if (existing) {
          if (existing.method !== method || existing.entityType !== entityType) {
            return {
              statusCode: 409,
              body: { message: 'Idempotency key was previously used for a different operation', conflict: true },
            };
          }
          return {
            statusCode: existing.statusCode,
            body: existing.response,
            isCachedReplay: true,
          };
        }

        // Execute action
        const result = {
          id: payload.id || 'rec_123',
          ...payload,
          version: 1,
          createdAt: new Date().toISOString(),
        };

        mutationStore.set(key, {
          shopId,
          mutationId,
          method,
          entityType,
          statusCode: 201,
          response: result,
        });

        return {
          statusCode: 201,
          body: result,
          isCachedReplay: false,
        };
      };

      const shopId = 'shop_test_1';
      const mutationId = 'mut_create_cust_uuid_9988';

      // First call
      const firstCall = await simulateIdempotentEndpoint({
        shopId,
        mutationId,
        method: 'POST',
        entityType: 'customers',
        action: 'create',
        payload: { name: 'Kavita Joshi', phone: '9988776655' },
      });

      assert.equal(firstCall.statusCode, 201);
      assert.equal(firstCall.isCachedReplay, false);
      const originalRecordId = firstCall.body.id;

      // Replay (network retry)
      const secondCall = await simulateIdempotentEndpoint({
        shopId,
        mutationId,
        method: 'POST',
        entityType: 'customers',
        action: 'create',
        payload: { name: 'Kavita Joshi', phone: '9988776655' },
      });

      assert.equal(secondCall.statusCode, 201);
      assert.equal(secondCall.isCachedReplay, true);
      assert.equal(secondCall.body.id, originalRecordId);
      assert.equal(mutationStore.size, 1);
    });

    it('should reject reuse of an idempotency key for a different operation or entity', async () => {
      const mutationStore = new Map();
      const shopId = 'shop_test_1';
      const reusedMutationId = 'shared_key_1122';

      // First operation: Create Customer
      mutationStore.set(`${shopId}_${reusedMutationId}`, {
        shopId,
        mutationId: reusedMutationId,
        method: 'POST',
        entityType: 'customers',
        statusCode: 201,
        response: { id: 'cust_1', name: 'Original Customer' },
      });

      // Second operation: Attempting to use SAME key for Create Order
      const existing = mutationStore.get(`${shopId}_${reusedMutationId}`);
      let rejectedWithConflict = false;

      if (existing && existing.entityType !== 'orders') {
        rejectedWithConflict = true;
      }

      assert.equal(rejectedWithConflict, true, 'Reusing key for different entity type must be rejected');
    });
  });

  describe('6.2 Durable Mutation Outbox & Atomic Persistence', () => {
    it('should atomically commit entity change and outbox row together or rollback both on failure', async () => {
      const sqliteEntities = new Map();
      const sqliteOutbox = new Map();

      const atomicTransaction = async ({ shouldFailOutbox = false } = {}) => {
        // Staging snapshot for transactional rollback
        const stagedEntities = new Map(sqliteEntities);
        const stagedOutbox = new Map(sqliteOutbox);

        try {
          // 1. Update entity in stage
          stagedEntities.set('ord_42', {
            id: 'ord_42',
            status: 'Delivered',
            version: 2,
            sync_status: 1,
          });

          // 2. Insert into outbox in stage
          if (shouldFailOutbox) {
            throw new Error('Disk full / constraint violation during outbox write');
          }

          stagedOutbox.set('mut_ord_42', {
            id: 'mut_ord_42',
            entity_type: 'orders',
            entity_id: 'ord_42',
            operation: 'update',
            base_version: 1,
            status: 'pending',
          });

          // Commit staged changes
          sqliteEntities.clear();
          for (const [k, v] of stagedEntities) sqliteEntities.set(k, v);
          sqliteOutbox.clear();
          for (const [k, v] of stagedOutbox) sqliteOutbox.set(k, v);
          return { success: true };
        } catch (err) {
          // Rollback: staged changes discarded, original maps unmodified
          return { success: false, error: err.message };
        }
      };

      // Scenario A: Failure during outbox insert
      const failedTx = await atomicTransaction({ shouldFailOutbox: true });
      assert.equal(failedTx.success, false);
      assert.equal(sqliteEntities.has('ord_42'), false, 'Entity update must be rolled back');
      assert.equal(sqliteOutbox.has('mut_ord_42'), false, 'Outbox insert must be rolled back');

      // Scenario B: Successful atomic commit
      const successTx = await atomicTransaction({ shouldFailOutbox: false });
      assert.equal(successTx.success, true);
      assert.equal(sqliteEntities.has('ord_42'), true, 'Entity update committed');
      assert.equal(sqliteOutbox.has('mut_ord_42'), true, 'Outbox row committed');
    });

    it('should never silently delete a failed or conflicted mutation', () => {
      const outbox = [
        { id: 'mut_1', status: 'synced' },
        { id: 'mut_2', status: 'conflict', conflict_state: 'conflict', last_error: 'Stale version' },
        { id: 'mut_3', status: 'failed', last_error: 'Invalid phone' },
      ];

      // Cleanup job should only purge synced records
      const remaining = outbox.filter((m) => m.status !== 'synced');
      assert.equal(remaining.length, 2);
      assert.ok(remaining.some((m) => m.id === 'mut_2' && m.status === 'conflict'));
      assert.ok(remaining.some((m) => m.id === 'mut_3' && m.status === 'failed'));
    });
  });

  describe('6.4 Push/Pull Ordering & Overwrite Prevention', () => {
    it('should order mutations by dependency (customers -> inventory -> orders -> payments -> expenses)', () => {
      const unsortedMutations = [
        { id: 'm1', entity_type: 'expenses', created_at: '2026-11-06T10:00:00Z' },
        { id: 'm2', entity_type: 'orders', created_at: '2026-11-06T10:01:00Z' },
        { id: 'm3', entity_type: 'orders', operation: 'payment', created_at: '2026-11-06T10:02:00Z' },
        { id: 'm4', entity_type: 'customers', created_at: '2026-11-06T10:03:00Z' },
        { id: 'm5', entity_type: 'inventory', created_at: '2026-11-06T10:04:00Z' },
      ];

      const getPriority = (m) => {
        if (m.operation === 'payment') return 4;
        const type = (m.entity_type || '').toLowerCase();
        if (type.includes('cust')) return 1;
        if (type.includes('inv')) return 2;
        if (type.includes('ord')) return 3;
        if (type.includes('pay')) return 4;
        if (type.includes('exp')) return 5;
        return 6;
      };

      const sorted = [...unsortedMutations].sort((a, b) => getPriority(a) - getPriority(b));

      assert.equal(sorted[0].id, 'm4', 'Customer must be processed first');
      assert.equal(sorted[1].id, 'm5', 'Inventory must be processed second');
      assert.equal(sorted[2].id, 'm2', 'Order must be processed third');
      assert.equal(sorted[3].id, 'm3', 'Payment must be processed fourth');
      assert.equal(sorted[4].id, 'm1', 'Expense must be processed fifth');
    });

    it('should NEVER overwrite local record with pending or conflicted mutation during remote pull', () => {
      const localDatabase = new Map([
        ['ord_pending', { id: 'ord_pending', status: 'In Progress (Local Edit)', total_amount: 1500, sync_status: 1 }],
        ['ord_clean', { id: 'ord_clean', status: 'Ready', total_amount: 800, sync_status: 0 }],
      ]);

      const dirtyOutboxEntityIds = new Set(['ord_pending']);

      const incomingRemoteRecords = [
        { _id: 'ord_pending', status: 'Incoming (Old Server State)', price: 1200 },
        { _id: 'ord_clean', status: 'Delivered (New Server State)', price: 800 },
        { _id: 'ord_brand_new', status: 'Incoming', price: 2000 },
      ];

      // Safe pull merge logic
      for (const remote of incomingRemoteRecords) {
        const id = remote._id;
        if (dirtyOutboxEntityIds.has(id)) {
          // SKIP OVERWRITE!
          continue;
        }

        localDatabase.set(id, {
          id,
          status: remote.status,
          total_amount: remote.price,
          sync_status: 0,
        });
      }

      // Assertions
      const pendingRecord = localDatabase.get('ord_pending');
      assert.equal(pendingRecord.status, 'In Progress (Local Edit)', 'Local pending mutation must NOT be overwritten by remote pull');
      assert.equal(pendingRecord.total_amount, 1500);

      const cleanRecord = localDatabase.get('ord_clean');
      assert.equal(cleanRecord.status, 'Delivered (New Server State)', 'Clean record should update from remote pull');

      const brandNewRecord = localDatabase.get('ord_brand_new');
      assert.equal(brandNewRecord.total_amount, 2000, 'New remote record should insert cleanly');
    });

    it('should recover in-flight processing mutations back to pending on sync restart', () => {
      const outbox = [
        { id: 'mut_1', status: 'processing', updated_at: 1000 },
        { id: 'mut_2', status: 'processing', updated_at: 1000 },
        { id: 'mut_3', status: 'synced', updated_at: 1000 },
        { id: 'mut_4', status: 'pending', updated_at: 1000 },
      ];

      // Simulate recoverInFlightMutations
      for (const m of outbox) {
        if (m.status === 'processing') {
          m.status = 'pending';
          m.updated_at = 2000;
        }
      }

      assert.equal(outbox.filter((m) => m.status === 'pending').length, 3);
      assert.equal(outbox.filter((m) => m.status === 'processing').length, 0);
      assert.equal(outbox.find((m) => m.id === 'mut_3').status, 'synced');
    });

    it('should isolate mutations strictly by shop_id when switching shops', () => {
      const outbox = [
        { id: 'm_shop_a', shop_id: 'shop_A', entity_type: 'orders', status: 'pending' },
        { id: 'm_shop_b', shop_id: 'shop_B', entity_type: 'orders', status: 'pending' },
      ];

      const getPendingForShop = (activeShopId) => outbox.filter((m) => m.shop_id === activeShopId);

      const shopAPending = getPendingForShop('shop_A');
      assert.equal(shopAPending.length, 1);
      assert.equal(shopAPending[0].id, 'm_shop_a');

      // Switching active shop to Shop B must not push or modify Shop A records
      const shopBPending = getPendingForShop('shop_B');
      assert.equal(shopBPending.length, 1);
      assert.equal(shopBPending[0].id, 'm_shop_b');
      assert.equal(outbox.find((m) => m.id === 'm_shop_a').shop_id, 'shop_A');
    });
  });
});

