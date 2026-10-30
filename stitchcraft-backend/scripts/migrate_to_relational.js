/**
 * StitchCraft Relational Schema Migration Script
 * ---------------------------------------------------------------------------
 * Migrates data from the JSONB document store (public.app_records)
 * into normalized domain tables defined in supabase/migrations/20261030150000_stitchcraft_schema.sql.
 *
 * Usage:
 *   node scripts/migrate_to_relational.js [--dry-run]
 */

import { supabase } from '../config/supabase.js';

const TABLE_MAPPINGS = {
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
        : (row.document?.customer || null),
      karigar_id: typeof row.document?.assignedKarigar === 'object'
        ? row.document.assignedKarigar?._id
        : (row.document?.assignedKarigar || null),
      machine_id: typeof row.document?.assignedMachine === 'object'
        ? row.document.assignedMachine?._id
        : (row.document?.assignedMachine || null),
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

// If run directly from CLI
if (process.argv[1]?.endsWith('migrate_to_relational.js')) {
  const isDryRun = process.argv.includes('--dry-run');
  runMigration({ isDryRun })
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('[Migration Fatal Error]:', err);
      process.exit(1);
    });
}

