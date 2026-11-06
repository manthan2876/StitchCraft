/**
 * StitchCraft Dual-Write and Relational Verification Service
 * ---------------------------------------------------------------------------
 * Manages incremental migration from document store (public.app_records)
 * to normalized domain tables.
 *
 * Supported Modes (via process.env.RELATIONAL_STORAGE_MODE):
 *   - 'legacy'     : Reads and writes strictly via app_records (default)
 *   - 'dual_write' : Writes to both app_records and domain tables; reads from app_records;
 *                    optionally performs shadow reads to verify parity.
 *   - 'relational' : Writes primarily to domain tables (and legacy for safety); reads from domain tables.
 */

import crypto from 'node:crypto';
import { supabase } from '../config/supabase.js';

export const STORAGE_MODES = {
  LEGACY: 'legacy',
  DUAL_WRITE: 'dual_write',
  RELATIONAL: 'relational',
};

// Global telemetry for shadow reads and dual-write operations
const dualWriteMetrics = {
  writesCount: 0,
  writesSucceeded: 0,
  writesFailed: 0,
  shadowReadsCount: 0,
  shadowMatches: 0,
  shadowMismatches: 0,
  discrepancies: [],
};

export const getStorageMode = () => {
  const mode = (process.env.RELATIONAL_STORAGE_MODE || '').toLowerCase();
  if (mode === STORAGE_MODES.DUAL_WRITE || mode === 'dual') return STORAGE_MODES.DUAL_WRITE;
  if (mode === STORAGE_MODES.RELATIONAL) return STORAGE_MODES.RELATIONAL;
  if (process.env.ENABLE_RELATIONAL_STORAGE === 'true') return STORAGE_MODES.DUAL_WRITE;
  return STORAGE_MODES.LEGACY;
};

export const isDualWriteEnabled = () => {
  const mode = getStorageMode();
  return mode === STORAGE_MODES.DUAL_WRITE || mode === STORAGE_MODES.RELATIONAL;
};

export const isRelationalPrimary = () => {
  return getStorageMode() === STORAGE_MODES.RELATIONAL;
};

export const isShadowReadEnabled = () => {
  return process.env.SHADOW_READ_ENABLED === 'true' || isDualWriteEnabled();
};

export const getDualWriteMetrics = () => ({ ...dualWriteMetrics });

export const resetDualWriteMetrics = () => {
  dualWriteMetrics.writesCount = 0;
  dualWriteMetrics.writesSucceeded = 0;
  dualWriteMetrics.writesFailed = 0;
  dualWriteMetrics.shadowReadsCount = 0;
  dualWriteMetrics.shadowMatches = 0;
  dualWriteMetrics.shadowMismatches = 0;
  dualWriteMetrics.discrepancies = [];
};

/**
 * Domain table column extractors for high-volume and high-integrity entities.
 */
export const RELATIONAL_TABLE_CONFIGS = {
  users: {
    table: 'users',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      supabase_id: doc.supabaseId || null,
      email: doc.email || null,
      shop_id: typeof doc.shopId === 'object' ? doc.shopId?._id : (doc.shopId || null),
      document: doc,
    }),
  },
  shops: {
    table: 'shops',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      owner_id: doc.ownerId || null,
      document: doc,
    }),
  },
  customers: {
    table: 'customers',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      phone: doc.phone || null,
      name: doc.name || null,
      is_deleted: Boolean(doc.isDeleted),
      document: doc,
    }),
  },
  orders: {
    table: 'orders',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      customer_id: typeof doc.customer === 'object' ? doc.customer?._id : (doc.customer || doc.customerId || null),
      karigar_id: typeof doc.assignedKarigar === 'object' ? doc.assignedKarigar?._id : (doc.assignedKarigar || null),
      machine_id: typeof doc.assignedMachine === 'object' ? doc.assignedMachine?._id : (doc.assignedMachine || null),
      status: doc.status || 'Pending',
      price: doc.price !== undefined ? Number(doc.price) : 0,
      delivery_date: doc.deliveryDate || null,
      is_deleted: Boolean(doc.isDeleted),
      delegated_to_shop_id: doc.delegatedToShopId || null,
      document: doc,
    }),
  },
  payments: {
    table: 'payments',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      order_id: doc.orderId || null,
      amount: doc.amount !== undefined ? Number(doc.amount) : 0,
      balance_amount: doc.balanceAmount !== undefined ? Number(doc.balanceAmount) : 0,
      payment_status: doc.paymentStatus || 'Pending',
      document: doc,
    }),
  },
  transactions: {
    table: 'transactions',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      order_id: doc.orderId || null,
      payment_id: doc.paymentId || null,
      document: doc,
    }),
  },
  ledger_entries: {
    table: 'ledger_entries',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      amount: doc.amount !== undefined ? Number(doc.amount) : 0,
      type: doc.type || 'credit',
      category: doc.category || 'general',
      entry_date: doc.date || doc.entryDate || new Date().toISOString().slice(0, 10),
      document: doc,
    }),
  },
  inventory: {
    table: 'inventory',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      item_name: doc.name || doc.itemName || null,
      stock_quantity: doc.quantity !== undefined ? Number(doc.quantity) : 0,
      unit: doc.unit || 'meters',
      document: doc,
    }),
  },
  measurements: {
    table: 'measurements',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      customer_id: doc.customerId || null,
      document: doc,
    }),
  },
  deliveries: {
    table: 'deliveries',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      order_id: doc.orderId || null,
      document: doc,
    }),
  },
  karigars: {
    table: 'karigars',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      document: doc,
    }),
  },
  machines: {
    table: 'machines',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      document: doc,
    }),
  },
  notifications: {
    table: 'notifications',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      user_id: doc.userId || null,
      document: doc,
    }),
  },
  action_logs: {
    table: 'action_logs',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      user_id: doc.userId || null,
      order_id: doc.orderId || null,
      document: doc,
    }),
  },
  sync_mutations: {
    table: 'sync_mutations',
    extract: (doc) => ({
      id: String(doc._id || doc.id || doc.mutationId),
      shop_id: doc.shopId || null,
      mutation_id: doc.mutationId || String(doc._id || doc.id),
      entity: doc.entity || 'unknown',
      action: doc.action || 'create',
      version: doc.version || 1,
      payload: doc.payload || doc,
      status: doc.status || 'applied',
      document: doc,
    }),
  },
  inventory_movements: {
    table: 'inventory_movements',
    extract: (doc) => ({
      id: String(doc._id || doc.id),
      shop_id: doc.shopId || null,
      item_id: doc.itemId || null,
      order_id: doc.orderId || null,
      type: doc.type || 'consumption',
      quantity: Number(doc.quantity || 0),
      unit: doc.unit || 'meters',
      notes: doc.notes || null,
      document: doc,
    }),
  },
};

/**
 * Transforms an in-memory document into a typed relational table row.
 */
export const transformDocumentToRelational = (collection, document) => {
  const config = RELATIONAL_TABLE_CONFIGS[collection];
  if (!config) return null;
  return config.extract(document);
};

/**
 * Executes dual-write upsert to normalized domain table if mode is active.
 */
export const recordDualWrite = async (collection, document) => {
  if (!isDualWriteEnabled()) return null;

  const config = RELATIONAL_TABLE_CONFIGS[collection];
  if (!config) return null;

  dualWriteMetrics.writesCount++;
  try {
    const row = config.extract(document);
    const { error } = await supabase
      .from(config.table)
      .upsert(row, { onConflict: 'id' });

    if (error) {
      dualWriteMetrics.writesFailed++;
      console.warn(`[DualWrite] Warning: failed to upsert ${config.table} (${row.id}):`, error.message);
      return { success: false, error: error.message };
    }

    dualWriteMetrics.writesSucceeded++;
    return { success: true, table: config.table, id: row.id };
  } catch (err) {
    dualWriteMetrics.writesFailed++;
    console.warn(`[DualWrite] Exception writing to ${config.table}:`, err.message);
    return { success: false, error: err.message };
  }
};

/**
 * Executes dual-write delete on domain table.
 */
export const recordDualDelete = async (collection, id) => {
  if (!isDualWriteEnabled()) return null;

  const config = RELATIONAL_TABLE_CONFIGS[collection];
  if (!config) return null;

  try {
    const { error } = await supabase
      .from(config.table)
      .delete()
      .eq('id', String(id));

    if (error) {
      console.warn(`[DualWrite] Warning: failed to delete from ${config.table} (${id}):`, error.message);
      return false;
    }
    return true;
  } catch (err) {
    console.warn(`[DualWrite] Exception deleting from ${config.table}:`, err.message);
    return false;
  }
};

/**
 * Compares legacy vs relational representation during shadow read mode.
 */
export const performShadowComparison = (collection, legacyDocs, relationalDocs) => {
  if (!isShadowReadEnabled()) return { match: true };

  dualWriteMetrics.shadowReadsCount++;
  const lCount = Array.isArray(legacyDocs) ? legacyDocs.length : (legacyDocs ? 1 : 0);
  const rCount = Array.isArray(relationalDocs) ? relationalDocs.length : (relationalDocs ? 1 : 0);

  if (lCount !== rCount) {
    dualWriteMetrics.shadowMismatches++;
    const diff = {
      collection,
      reason: `Count mismatch: legacy=${lCount}, relational=${rCount}`,
      timestamp: new Date().toISOString(),
    };
    dualWriteMetrics.discrepancies.push(diff);
    return { match: false, diff };
  }

  // Sample ID check
  if (Array.isArray(legacyDocs) && Array.isArray(relationalDocs) && legacyDocs.length > 0) {
    const legacyIds = new Set(legacyDocs.map((d) => String(d._id || d.id)));
    const missingInRelational = relationalDocs.filter((r) => !legacyIds.has(String(r.id || r._id)));
    if (missingInRelational.length > 0) {
      dualWriteMetrics.shadowMismatches++;
      const diff = {
        collection,
        reason: `ID divergence: ${missingInRelational.length} records missing in legacy set`,
        timestamp: new Date().toISOString(),
      };
      dualWriteMetrics.discrepancies.push(diff);
      return { match: false, diff };
    }
  }

  dualWriteMetrics.shadowMatches++;
  return { match: true };
};

/**
 * Validates count and ID parity between app_records and relational tables.
 */
export const validateMigrationParity = async ({ collection, shopId } = {}) => {
  const config = RELATIONAL_TABLE_CONFIGS[collection];
  if (!config) throw new Error(`Collection '${collection}' is not registered in relational mappings.`);

  // 1. Fetch from app_records
  let appRecordsQuery = supabase
    .from('app_records')
    .select('source_id,document')
    .eq('collection', collection);

  if (shopId) {
    appRecordsQuery = appRecordsQuery.filter('document->>shopId', 'eq', shopId);
  }

  const { data: legacyData, error: legacyErr } = await appRecordsQuery;
  if (legacyErr) throw new Error(`Legacy read failed for ${collection}: ${legacyErr.message}`);

  // 2. Fetch from domain table
  let domainQuery = supabase
    .from(config.table)
    .select('id,shop_id,document');

  if (shopId) {
    domainQuery = domainQuery.eq('shop_id', shopId);
  }

  const { data: domainData, error: domainErr } = await domainQuery;
  if (domainErr) throw new Error(`Domain table read failed for ${config.table}: ${domainErr.message}`);

  const legacyIds = new Set((legacyData || []).map((r) => String(r.source_id)));
  const domainIds = new Set((domainData || []).map((r) => String(r.id)));

  const missingInDomain = [...legacyIds].filter((id) => !domainIds.has(id));
  const missingInLegacy = [...domainIds].filter((id) => !legacyIds.has(id));

  const isParity = missingInDomain.length === 0 && missingInLegacy.length === 0 && legacyIds.size === domainIds.size;

  return {
    collection,
    table: config.table,
    match: isParity,
    legacyCount: legacyIds.size,
    domainCount: domainIds.size,
    missingInDomain,
    missingInLegacy,
  };
};
