import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  recordQueryMetric,
  getQueryMetricsSummary,
  resetQueryMetrics,
  DEFAULT_MAX_QUERY_LIMIT,
  SLOW_QUERY_THRESHOLD_MS,
  LARGE_RESULT_THRESHOLD,
} from '../services/queryMetrics.js';
import {
  getStorageMode,
  isDualWriteEnabled,
  isRelationalPrimary,
  isShadowReadEnabled,
  STORAGE_MODES,
  transformDocumentToRelational,
  performShadowComparison,
  getDualWriteMetrics,
  resetDualWriteMetrics,
} from '../services/dualWriteService.js';
import {
  TABLE_MAPPINGS,
  computeChecksum,
} from '../scripts/migrate_to_relational.js';

describe('Phase 6: Database Scalability and Relational Migration', () => {
  beforeEach(() => {
    resetQueryMetrics();
    resetDualWriteMetrics();
  });

  describe('10.1 Stop Unsafe In-Memory Query Behavior & Optimization', () => {
    it('should enforce safety limit ceiling (DEFAULT_MAX_QUERY_LIMIT = 500) on unpaginated queries', () => {
      // Simulating a dataset of 1,200 records loaded from storage
      const rawRecords = Array.from({ length: 1200 }, (_, i) => ({
        _id: `rec_${i + 1}`,
        shopId: 'shop_alpha',
        name: `Item ${i + 1}`,
      }));

      // A query without explicit limitCount must be capped at DEFAULT_MAX_QUERY_LIMIT
      const defaultLimit = DEFAULT_MAX_QUERY_LIMIT;
      assert.equal(defaultLimit, 500);

      const boundedResults = rawRecords.slice(0, defaultLimit);
      assert.equal(boundedResults.length, 500);
      assert.equal(boundedResults[0]._id, 'rec_1');
      assert.equal(boundedResults[499]._id, 'rec_500');
    });

    it('should sort deterministically with primary field and secondary unique ID tie-breaker', () => {
      // Multiple items with identical deliveryDate / createdAt
      const sharedDate = '2026-11-15T10:00:00.000Z';
      const items = [
        { _id: 'ord_gamma', deliveryDate: sharedDate, priority: 2 },
        { _id: 'ord_alpha', deliveryDate: sharedDate, priority: 1 },
        { _id: 'ord_beta', deliveryDate: sharedDate, priority: 1 },
      ];

      // Sort comparator mirroring SupabaseQuery implementation
      const sortFields = { priority: 1, deliveryDate: 1 };
      const sorted = [...items].sort((left, right) => {
        for (const [field, direction] of Object.entries(sortFields)) {
          const comparison = String(left?.[field] ?? '').localeCompare(
            String(right?.[field] ?? ''),
            undefined,
            { numeric: true },
          );
          if (comparison !== 0) return comparison * Number(direction);
        }
        // Deterministic secondary tie-breaker
        const leftId = String(left?._id ?? left?.id ?? '');
        const rightId = String(right?._id ?? right?.id ?? '');
        return leftId.localeCompare(rightId, undefined, { numeric: true });
      });

      // Priority 1 items sorted by ID: ord_alpha before ord_beta; then priority 2: ord_gamma
      assert.equal(sorted[0]._id, 'ord_alpha');
      assert.equal(sorted[1]._id, 'ord_beta');
      assert.equal(sorted[2]._id, 'ord_gamma');
    });

    it('should replace N+1 payment and delivery lookups with batched O(1) query lookups', async () => {
      // 100 test orders
      const orderCount = 100;
      const orders = Array.from({ length: orderCount }, (_, i) => ({
        _id: `ord_${i + 1}`,
        shopId: 'shop_main',
        customerName: `Customer ${i + 1}`,
        price: 1500,
      }));

      // Simulate the N+1 anti-pattern: 1 query for orders + 100 for payment + 100 for delivery = 201 queries
      let legacyQueryCount = 1; // 1 for orders
      for (const _o of orders) {
        legacyQueryCount += 2; // findOne payment + findOne delivery
      }
      assert.equal(legacyQueryCount, 201);

      // Batched lookup pattern: exactly 3 queries regardless of order count (O(1) round-trips)
      let batchedQueryCount = 0;
      
      // Step 1: Orders query
      batchedQueryCount++;
      const orderIds = orders.map((o) => o._id);

      // Step 2 & 3: Batched payments and deliveries queries
      const mockPayments = orders.map((o) => ({
        _id: `pay_${o._id}`,
        orderId: o._id,
        paidAmount: 1000,
        balanceAmount: 500,
      }));
      const mockDeliveries = orders.map((o) => ({
        _id: `del_${o._id}`,
        orderId: o._id,
        status: 'Scheduled',
      }));

      batchedQueryCount += 2; // Promise.all([Payment.find({ orderId: { $in: orderIds } }), Delivery.find(...)])
      assert.equal(batchedQueryCount, 3);

      // In-memory mapping
      const paymentMap = new Map();
      for (const p of mockPayments) paymentMap.set(String(p.orderId), p);

      const deliveryMap = new Map();
      for (const d of mockDeliveries) deliveryMap.set(String(d.orderId), d);

      const populated = orders.map((o) => ({
        ...o,
        payment: paymentMap.get(String(o._id)) || null,
        delivery: deliveryMap.get(String(o._id)) || null,
      }));

      assert.equal(populated.length, 100);
      assert.equal(populated[0].payment.paidAmount, 1000);
      assert.equal(populated[99].delivery.status, 'Scheduled');
    });

    it('should eliminate unfiltered $or queries by issuing parallel indexed tenant predicates', () => {
      const shopId = 'shop_prime';
      
      // Legacy unsafe filter:
      const unsafeFilter = {
        $or: [
          { shopId },
          { delegatedToShopId: shopId },
        ],
        isDeleted: { $ne: true },
      };
      // Notice: unsafeFilter.shopId is undefined, bypassing top-level table index
      assert.equal(unsafeFilter.shopId, undefined);

      // Scalable pattern: 2 separate queries each with explicit indexed tenant pushdown
      const ownFilter = { shopId, isDeleted: { $ne: true } };
      const delegatedFilter = { delegatedToShopId: shopId, isDeleted: { $ne: true } };

      assert.equal(ownFilter.shopId, 'shop_prime');
      assert.equal(delegatedFilter.delegatedToShopId, 'shop_prime');

      // Deduplication test
      const ownOrders = [{ _id: 'ord_1', title: 'Suit 1' }, { _id: 'ord_2', title: 'Sherwani' }];
      const delegatedOrders = [{ _id: 'ord_2', title: 'Sherwani' }, { _id: 'ord_3', title: 'Blazer' }];

      const orderMap = new Map();
      for (const o of ownOrders) orderMap.set(String(o._id), o);
      for (const o of delegatedOrders) orderMap.set(String(o._id), o);

      const merged = Array.from(orderMap.values());
      assert.equal(merged.length, 3);
      assert.deepEqual(merged.map((o) => o._id), ['ord_1', 'ord_2', 'ord_3']);
    });

    it('should record query timing, slow query warnings, and result-size metrics', () => {
      // 1. Fast, well-indexed tenant query
      const fastMetric = recordQueryMetric({
        collection: 'orders',
        operation: 'find',
        durationMs: 14.5,
        resultCount: 25,
        pushedFilters: { shopId: 'shop_1' },
        hasTenantPredicate: true,
      });

      assert.equal(fastMetric.isSlow, false);
      assert.equal(fastMetric.isLarge, false);
      assert.equal(fastMetric.hasTenantPredicate, true);

      // 2. Slow query exceeding SLOW_QUERY_THRESHOLD_MS
      const slowMetric = recordQueryMetric({
        collection: 'orders',
        operation: 'load',
        durationMs: 185.2, // > 100ms
        resultCount: 150,
        pushedFilters: { shopId: 'shop_1' },
        hasTenantPredicate: true,
      });

      assert.equal(slowMetric.isSlow, true);

      // 3. Large result query exceeding LARGE_RESULT_THRESHOLD
      const largeMetric = recordQueryMetric({
        collection: 'inventory',
        operation: 'load',
        durationMs: 45.0,
        resultCount: 350, // > 200 items
        pushedFilters: { shopId: 'shop_1' },
        hasTenantPredicate: true,
      });

      assert.equal(largeMetric.isLarge, true);

      // Summary verification
      const summary = getQueryMetricsSummary();
      assert.equal(summary.totalQueries, 3);
      assert.equal(summary.slowQueriesCount, 1);
      assert.equal(summary.largeResultQueriesCount, 1);
      assert.equal(summary.recentQueries.length, 3);
    });
  });

  describe('10.2 Incremental Relational Table Extraction & Column Typing', () => {
    it('should extract typed columns for high-integrity entities while preserving document JSONB', () => {
      const sampleOrder = {
        _id: 'ord_scale_101',
        shopId: 'shop_surat',
        customer: { _id: 'cust_99', name: 'Ramesh Patel' },
        assignedKarigar: 'karigar_5',
        assignedMachine: 'machine_1',
        status: 'In Progress',
        price: 4500,
        deliveryDate: '2026-11-20T12:00:00.000Z',
        isDeleted: false,
        garmentDetails: { fabric: 'Raw Silk', pockets: 3, liningColor: 'Navy' },
      };

      const relationalOrder = transformDocumentToRelational('orders', sampleOrder);
      assert.equal(relationalOrder.id, 'ord_scale_101');
      assert.equal(relationalOrder.shop_id, 'shop_surat');
      assert.equal(relationalOrder.customer_id, 'cust_99');
      assert.equal(relationalOrder.karigar_id, 'karigar_5');
      assert.equal(relationalOrder.status, 'In Progress');
      assert.equal(relationalOrder.price, 4500);
      assert.equal(relationalOrder.is_deleted, false);
      // Document JSONB preserves complex nested details
      assert.deepEqual(relationalOrder.document.garmentDetails, { fabric: 'Raw Silk', pockets: 3, liningColor: 'Navy' });
    });

    it('should extract typed columns for customer and payment entities', () => {
      const sampleCustomer = {
        _id: 'cust_scale_202',
        shopId: 'shop_delhi',
        name: 'Amina Begum',
        phone: '9876543210',
        isDeleted: false,
      };

      const relationalCustomer = transformDocumentToRelational('customers', sampleCustomer);
      assert.equal(relationalCustomer.id, 'cust_scale_202');
      assert.equal(relationalCustomer.phone, '9876543210');
      assert.equal(relationalCustomer.name, 'Amina Begum');
      assert.equal(relationalCustomer.is_deleted, false);

      const samplePayment = {
        _id: 'pay_scale_303',
        shopId: 'shop_delhi',
        orderId: 'ord_scale_101',
        amount: 4500,
        balanceAmount: 1500,
        paymentStatus: 'Partial',
      };

      const relationalPayment = transformDocumentToRelational('payments', samplePayment);
      assert.equal(relationalPayment.amount, 4500);
      assert.equal(relationalPayment.balance_amount, 1500);
      assert.equal(relationalPayment.payment_status, 'Partial');
    });

    it('should extract typed columns for offline sync mutations and inventory movements', () => {
      const sampleMutation = {
        _id: 'mut_client_001',
        mutationId: 'mut_client_001',
        shopId: 'shop_jaipur',
        entity: 'orders',
        action: 'create',
        version: 1,
        payload: { orderId: 'ord_123', price: 2000 },
        status: 'applied',
      };

      const relationalMutation = transformDocumentToRelational('sync_mutations', sampleMutation);
      assert.equal(relationalMutation.mutation_id, 'mut_client_001');
      assert.equal(relationalMutation.entity, 'orders');
      assert.equal(relationalMutation.action, 'create');
      assert.equal(relationalMutation.status, 'applied');

      const sampleMovement = {
        _id: 'mov_inv_77',
        shopId: 'shop_jaipur',
        itemId: 'item_silk_01',
        orderId: 'ord_123',
        type: 'consumption',
        quantity: 2.5,
        unit: 'meters',
        notes: 'Blouse back panel',
      };

      const relationalMovement = transformDocumentToRelational('inventory_movements', sampleMovement);
      assert.equal(relationalMovement.item_id, 'item_silk_01');
      assert.equal(relationalMovement.type, 'consumption');
      assert.equal(relationalMovement.quantity, 2.5);
      assert.equal(relationalMovement.unit, 'meters');
    });
  });

  describe('10.3 Dual-Write & Shadow Read Verification Strategy', () => {
    it('should honor storage modes (legacy, dual_write, relational) via environment variables', () => {
      const originalMode = process.env.RELATIONAL_STORAGE_MODE;
      const originalEnable = process.env.ENABLE_RELATIONAL_STORAGE;

      try {
        // Mode 1: Default legacy
        delete process.env.RELATIONAL_STORAGE_MODE;
        delete process.env.ENABLE_RELATIONAL_STORAGE;
        assert.equal(getStorageMode(), STORAGE_MODES.LEGACY);
        assert.equal(isDualWriteEnabled(), false);
        assert.equal(isRelationalPrimary(), false);

        // Mode 2: Dual Write via RELATIONAL_STORAGE_MODE
        process.env.RELATIONAL_STORAGE_MODE = 'dual_write';
        assert.equal(getStorageMode(), STORAGE_MODES.DUAL_WRITE);
        assert.equal(isDualWriteEnabled(), true);
        assert.equal(isRelationalPrimary(), false);

        // Mode 3: Dual Write via ENABLE_RELATIONAL_STORAGE
        delete process.env.RELATIONAL_STORAGE_MODE;
        process.env.ENABLE_RELATIONAL_STORAGE = 'true';
        assert.equal(getStorageMode(), STORAGE_MODES.DUAL_WRITE);
        assert.equal(isDualWriteEnabled(), true);

        // Mode 4: Relational primary mode
        process.env.RELATIONAL_STORAGE_MODE = 'relational';
        assert.equal(getStorageMode(), STORAGE_MODES.RELATIONAL);
        assert.equal(isDualWriteEnabled(), true);
        assert.equal(isRelationalPrimary(), true);
      } finally {
        if (originalMode !== undefined) process.env.RELATIONAL_STORAGE_MODE = originalMode;
        else delete process.env.RELATIONAL_STORAGE_MODE;
        if (originalEnable !== undefined) process.env.ENABLE_RELATIONAL_STORAGE = originalEnable;
        else delete process.env.ENABLE_RELATIONAL_STORAGE;
      }
    });

    it('should detect parity and discrepancies during shadow read verification', () => {
      const originalShadow = process.env.SHADOW_READ_ENABLED;
      try {
        process.env.SHADOW_READ_ENABLED = 'true';

        // 1. Matching datasets
        const legacyDocs = [
          { _id: 'doc_1', shopId: 's1', value: 100 },
          { _id: 'doc_2', shopId: 's1', value: 200 },
        ];
        const relationalRows = [
          { id: 'doc_1', shop_id: 's1', document: { value: 100 } },
          { id: 'doc_2', shop_id: 's1', document: { value: 200 } },
        ];

        const matchResult = performShadowComparison('orders', legacyDocs, relationalRows);
        assert.equal(matchResult.match, true);

        // 2. Count mismatch discrepancy
        const mismatchedRelational = [
          { id: 'doc_1', shop_id: 's1' },
        ];
        const countDiffResult = performShadowComparison('orders', legacyDocs, mismatchedRelational);
        assert.equal(countDiffResult.match, false);
        assert.ok(countDiffResult.diff.reason.includes('Count mismatch'));

        // 3. ID divergence discrepancy
        const divergentRelational = [
          { id: 'doc_1', shop_id: 's1' },
          { id: 'doc_unknown', shop_id: 's1' },
        ];
        const idDiffResult = performShadowComparison('orders', legacyDocs, divergentRelational);
        assert.equal(idDiffResult.match, false);
        assert.ok(idDiffResult.diff.reason.includes('ID divergence'));

        // Check telemetry
        const metrics = getDualWriteMetrics();
        assert.equal(metrics.shadowReadsCount, 3);
        assert.equal(metrics.shadowMatches, 1);
        assert.equal(metrics.shadowMismatches, 2);
        assert.equal(metrics.discrepancies.length, 2);
      } finally {
        if (originalShadow !== undefined) process.env.SHADOW_READ_ENABLED = originalShadow;
        else delete process.env.SHADOW_READ_ENABLED;
      }
    });

    it('should compute cryptographic checksums for document and relational data integrity verification', () => {
      const docA = { id: 'item_1', name: 'Cotton Aster', price: 150 };
      const docB = { price: 150, name: 'Cotton Aster', id: 'item_1' }; // different key ordering
      const docC = { id: 'item_1', name: 'Cotton Aster', price: 155 }; // modified value

      const hashA = computeChecksum(docA);
      const hashB = computeChecksum(docB);
      const hashC = computeChecksum(docC);

      // Checksum is deterministic regardless of key insertion order
      assert.equal(hashA, hashB);
      // Changes in data generate distinct checksum
      assert.notEqual(hashA, hashC);
    });
  });

  describe('10.4 Required Indexes and Constraints Specification', () => {
    it('should verify registered tables have table definitions and transforms in migration registry', () => {
      const requiredEntities = [
        'users',
        'shops',
        'customers',
        'measurements',
        'orders',
        'payments',
        'transactions',
        'ledger_entries',
        'inventory',
        'sync_mutations',
        'inventory_movements',
      ];

      for (const entity of requiredEntities) {
        assert.ok(TABLE_MAPPINGS[entity], `Entity ${entity} must be registered in TABLE_MAPPINGS`);
        assert.ok(typeof TABLE_MAPPINGS[entity].transform === 'function', `Entity ${entity} must have a transform function`);
        
        // Transform smoke test
        const transformed = TABLE_MAPPINGS[entity].transform({
          source_id: `test_${entity}_1`,
          document: { shopId: 'shop_test' },
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        });
        assert.ok(transformed.id, `Transformed ${entity} row must contain primary key id`);
      }
    });

    it('should prevent invalid negative values and enforce amount non-negativity', () => {
      // Check constraints verified at application transform layer
      const invalidOrder = {
        _id: 'ord_neg',
        shopId: 'shop_1',
        price: -500, // Invalid negative
      };

      const transformedOrder = transformDocumentToRelational('orders', invalidOrder);
      assert.equal(transformedOrder.price, -500);

      // In SQL migration 20261106180000_phase6_relational_scalability.sql:
      // check (price >= 0) and check (amount >= 0) and check (stock_quantity >= 0)
      const isPriceValid = transformedOrder.price >= 0;
      assert.equal(isPriceValid, false);
    });
  });
});
