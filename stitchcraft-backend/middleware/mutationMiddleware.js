import SyncMutation from '../models/SyncMutation.js';

/**
 * Server-Side Mutation Idempotency Middleware
 * Ensures operations with Idempotency-Key or clientMutationId execute exactly once per shop.
 */
export const enforceMutationIdempotency = (entityType = 'generic') => async (req, res, next) => {
  const mutationId = req.headers['idempotency-key'] ||
    req.body?.idempotencyKey ||
    req.body?.clientMutationId ||
    req.body?.client_mutation_id;

  if (!mutationId || !req.user?.shopId) {
    return next();
  }

  const shopId = req.user.shopId;

  try {
    const existing = await SyncMutation.findOne({ shopId, mutationId });
    if (existing) {
      // Validate operation signature to prevent key reuse with differing parameters
      const sameMethod = !existing.method || existing.method === req.method;
      const sameEntity = !existing.entityType || existing.entityType === entityType;

      if (!sameMethod || !sameEntity) {
        return res.status(409).json({
          message: 'Idempotency key was previously used for a different operation',
          code: 'IDEMPOTENCY_KEY_REUSED',
          conflict: true,
        });
      }

      // Safe replay: return identical cached response
      return res.status(existing.statusCode || 200).json(existing.response);
    }

    // Intercept successful completion to persist idempotency cache
    const originalJson = res.json.bind(res);
    res.json = function (data) {
      const statusCode = res.statusCode || 200;
      if (statusCode >= 200 && statusCode < 300) {
        SyncMutation.create({
          shopId,
          mutationId,
          method: req.method,
          path: req.originalUrl || req.baseUrl || req.path,
          entityType,
          statusCode,
          response: data,
          createdAt: new Date().toISOString(),
        }).catch((err) => {
          console.error('Failed to commit mutation idempotency record:', err);
        });
      }
      return originalJson(data);
    };

    next();
  } catch (err) {
    console.error('Error verifying mutation idempotency:', err);
    next();
  }
};

export default enforceMutationIdempotency;

