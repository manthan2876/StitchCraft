/**
 * StitchCraft Relational Schema Migration Script
 * ---------------------------------------------------------------------------
 * Migrates data from the JSONB document store (public.app_records)
 * into normalized domain tables defined in supabase/migrations/20261030150000_stitchcraft_schema.sql
 * and 20261106180000_phase6_relational_scalability.sql.
 *
 * Usage:
 *   node scripts/migrate_to_relational.js [--dry-run] [--verify]
 */

import crypto from 'node:crypto';
import { supabase } from '../config/supabase.js';

export const TABLE_MAPPINGS = {
  users: {
    table: 'users',
    transform: (row) => ({
      id: row.source_id,
      supabase_id: row.document?.supabaseId || null,
      email: row.document?.email || null,
      shop_id: typeof row.document?.shopId === 'object'
        ? row.document.shopId?._id
        : (row.document?.shopId || null),
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  shops: {
    table: 'shops',
    transform: (row) => ({
      id: row.source_id,
      owner_id: row.document?.ownerId || null,
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  customers: {
    table: 'customers',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      phone: row.document?.phone || null,
      name: row.document?.name || null,
      is_deleted: Boolean(row.document?.isDeleted),
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  measurements: {
    table: 'measurements',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      customer_id: row.document?.customerId || null,
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  orders: {
    table: 'orders',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      customer_id: typeof row.document?.customer === 'object'
        ? row.document.customer?._id
        : (row.document?.customer || row.document?.customerId || null),
      karigar_id: typeof row.document?.assignedKarigar === 'object'
        ? row.document.assignedKarigar?._id
        : (row.document?.assignedKarigar || null),
      machine_id: typeof row.document?.assignedMachine === 'object'
        ? row.document.assignedMachine?._id
        : (row.document?.assignedMachine || null),
      status: row.document?.status || 'Pending',
      price: row.document?.price !== undefined ? Number(row.document.price) : 0,
      delivery_date: row.document?.deliveryDate || null,
      is_deleted: Boolean(row.document?.isDeleted),
      delegated_to_shop_id: row.document?.delegatedToShopId || null,
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  payments: {
    table: 'payments',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      order_id: row.document?.orderId || null,
      amount: row.document?.amount !== undefined ? Number(row.document.amount) : 0,
      balance_amount: row.document?.balanceAmount !== undefined ? Number(row.document.balanceAmount) : 0,
      payment_status: row.document?.paymentStatus || 'Pending',
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  transactions: {
    table: 'transactions',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      order_id: row.document?.orderId || null,
      payment_id: row.document?.paymentId || null,
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  ledger_entries: {
    table: 'ledger_entries',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      amount: row.document?.amount !== undefined ? Number(row.document.amount) : 0,
      type: row.document?.type || 'credit',
      category: row.document?.category || 'general',
      entry_date: row.document?.date || row.document?.entryDate || new Date().toISOString().slice(0, 10),
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  inventory: {
    table: 'inventory',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      item_name: row.document?.name || row.document?.itemName || null,
      stock_quantity: row.document?.quantity !== undefined ? Number(row.document.quantity) : 0,
      unit: row.document?.unit || 'meters',
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  karigars: {
    table: 'karigars',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  machines: {
    table: 'machines',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  deliveries: {
    table: 'deliveries',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      order_id: row.document?.orderId || null,
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  notifications: {
    table: 'notifications',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      user_id: row.document?.userId || null,
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  action_logs: {
    table: 'action_logs',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      user_id: row.document?.userId || null,
      order_id: row.document?.orderId || null,
      document: row.document,
      created_at: row.created_at,
      updated_at: row.updated_at,
    }),
  },
  sync_mutations: {
    table: 'sync_mutations',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      mutation_id: row.document?.mutationId || row.source_id,
      entity: row.document?.entity || 'unknown',
      action: row.document?.action || 'create',
      version: row.document?.version || 1,
      payload: row.document?.payload || row.document,
      status: row.document?.status || 'applied',
      applied_at: row.document?.appliedAt || row.created_at,
      created_at: row.created_at,
    }),
  },
  inventory_movements: {
    table: 'inventory_movements',
    transform: (row) => ({
      id: row.source_id,
      shop_id: row.document?.shopId || null,
      item_id: row.document?.itemId || null,
      order_id: row.document?.orderId || null,
      type: row.document?.type || 'consumption',
      quantity: Number(row.document?.quantity || 0),
      unit: row.document?.unit || 'meters',
      notes: row.document?.notes || null,
      created_at: row.created_at,
    }),
  },
};

export const computeChecksum = (data) => {
  const hash = crypto.createHash('sha256');
  const serialized = JSON.stringify(data, Object.keys(data).sort());
  hash.update(serialized);
  return hash.digest('hex');
};

export const runMigration = async ({ isDryRun = false } = {}) => {
  console.log(`[Migration] Starting schema transition from app_records -> relational domain tables...`);
  if (isDryRun) {
    console.log('[Migration] Mode: DRY RUN (no data will be written to relational tables)');
  }

  const results = {};

  for (const [collection, config] of Object.entries(TABLE_MAPPINGS)) {
    try {
      const { data: records, error } = await supabase
        .from('app_records')
        .select('*')
        .eq('collection', collection);

      if (error) {
        console.warn(`[Migration] Failed to read collection '${collection}':`, error.message);
        results[collection] = { status: 'FAILED_READ', error: error.message };
        continue;
      }

      if (!records || records.length === 0) {
        results[collection] = { count: 0, status: 'SKIPPED_EMPTY' };
        continue;
      }

      const transformedRows = records.map(config.transform);

      if (!isDryRun) {
        // Upsert in batches of 100
        const batchSize = 100;
        for (let i = 0; i < transformedRows.length; i += batchSize) {
          const batch = transformedRows.slice(i, i + batchSize);
          const { error: upsertError } = await supabase
            .from(config.table)
            .upsert(batch, { onConflict: 'id' });

          if (upsertError) {
            throw new Error(`Batch upsert into ${config.table} failed: ${upsertError.message}`);
          }
        }
      }

      results[collection] = {
        count: transformedRows.length,
        table: config.table,
        status: isDryRun ? 'DRY_RUN_OK' : 'MIGRATED',
      };
      console.log(`[Migration] ✓ Collection '${collection}': ${transformedRows.length} rows processed for table '${config.table}'`);
    } catch (err) {
      console.error(`[Migration] ✗ Error migrating '${collection}':`, err.message);
      results[collection] = { status: 'FAILED', error: err.message };
    }
  }

  console.log('\n================ MIGRATION REPORT ================');
  console.table(results);
  console.log('==================================================\n');
  return results;
};

/**
 * Validates count and ID parity across all collections.
 */
export const validateBackfillParity = async (collections = Object.keys(TABLE_MAPPINGS)) => {
  const report = {};
  for (const collection of collections) {
    const config = TABLE_MAPPINGS[collection];
    if (!config) continue;

    const [legacyRes, relationalRes] = await Promise.all([
      supabase.from('app_records').select('source_id').eq('collection', collection),
      supabase.from(config.table).select('id'),
    ]);

    const legacyIds = new Set((legacyRes.data || []).map((r) => String(r.source_id)));
    const relationalIds = new Set((relationalRes.data || []).map((r) => String(r.id)));

    const legacyCount = legacyIds.size;
    const relationalCount = relationalIds.size;
    const missingInRelational = [...legacyIds].filter((id) => !relationalIds.has(id));
    const isParity = legacyCount === relationalCount && missingInRelational.length === 0;

    report[collection] = {
      legacyCount,
      relationalCount,
      isParity,
      discrepancyCount: Math.abs(legacyCount - relationalCount) + missingInRelational.length,
    };
  }
  return report;
};

// If run directly from CLI
if (process.argv[1]?.endsWith('migrate_to_relational.js')) {
  const isDryRun = process.argv.includes('--dry-run');
  const isVerify = process.argv.includes('--verify');

  if (isVerify) {
    validateBackfillParity()
      .then((report) => {
        console.log('\n================ BACKFILL PARITY REPORT ================');
        console.table(report);
        process.exit(0);
      })
      .catch((err) => {
        console.error('[Verification Fatal Error]:', err);
        process.exit(1);
      });
  } else {
    runMigration({ isDryRun })
      .then(() => process.exit(0))
      .catch((err) => {
        console.error('[Migration Fatal Error]:', err);
        process.exit(1);
      });
  }
}
