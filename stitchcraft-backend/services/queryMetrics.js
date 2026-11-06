/**
 * StitchCraft Query Performance & Result-Size Metrics Telemetry
 * ---------------------------------------------------------------------------
 * Monitors query latency, result size, and tenant boundary pushdown.
 * Enforces safety query limits and emits diagnostics on unindexed/slow executions.
 */

export const DEFAULT_MAX_QUERY_LIMIT = 500;
export const SLOW_QUERY_THRESHOLD_MS = Number(process.env.SLOW_QUERY_THRESHOLD_MS) || 100;
export const LARGE_RESULT_THRESHOLD = Number(process.env.LARGE_RESULT_THRESHOLD) || 200;

const metricsState = {
  totalQueries: 0,
  slowQueriesCount: 0,
  largeResultQueriesCount: 0,
  recentQueries: [], // Ring buffer of last 100 queries
};

const MAX_RECENT_LOGS = 100;

export const recordQueryMetric = ({
  collection,
  operation = 'find',
  durationMs,
  resultCount,
  pushedFilters = {},
  hasTenantPredicate = false,
}) => {
  metricsState.totalQueries++;

  const isSlow = durationMs >= SLOW_QUERY_THRESHOLD_MS;
  const isLarge = resultCount >= LARGE_RESULT_THRESHOLD;

  if (isSlow) metricsState.slowQueriesCount++;
  if (isLarge) metricsState.largeResultQueriesCount++;

  const entry = {
    timestamp: new Date().toISOString(),
    collection,
    operation,
    durationMs: Number(durationMs.toFixed(2)),
    resultCount,
    pushedFilters,
    hasTenantPredicate,
    isSlow,
    isLarge,
  };

  metricsState.recentQueries.unshift(entry);
  if (metricsState.recentQueries.length > MAX_RECENT_LOGS) {
    metricsState.recentQueries.pop();
  }

  if (isSlow && process.env.NODE_ENV !== 'test') {
    console.warn(
      `[QueryMetrics] ⚠️ SLOW QUERY (${durationMs.toFixed(1)}ms): ${collection}.${operation} returned ${resultCount} rows. Filters:`,
      pushedFilters,
    );
  }

  if (!hasTenantPredicate && ['orders', 'customers', 'payments', 'transactions', 'ledger_entries', 'inventory'].includes(collection)) {
    if (process.env.NODE_ENV !== 'test') {
      console.warn(
        `[QueryMetrics] ⚠️ MISSING TENANT PREDICATE: ${collection}.${operation} ran without shop-level isolation predicate!`,
      );
    }
  }

  return entry;
};

export const getQueryMetricsSummary = () => ({
  totalQueries: metricsState.totalQueries,
  slowQueriesCount: metricsState.slowQueriesCount,
  largeResultQueriesCount: metricsState.largeResultQueriesCount,
  recentQueries: [...metricsState.recentQueries],
});

export const resetQueryMetrics = () => {
  metricsState.totalQueries = 0;
  metricsState.slowQueriesCount = 0;
  metricsState.largeResultQueriesCount = 0;
  metricsState.recentQueries = [];
};
