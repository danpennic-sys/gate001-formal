// middleware/replayGuard.js
// Atomic nonce / replay protection using Redis SET key value NX EX

/**
 * Creates an Express middleware that rejects replayed nonces.
 * @param {object} redisClient - a node-redis (or compatible) client
 * @param {object} [opts]
 * @param {number} [opts.ttlSeconds=60]
 * @param {function} [opts.keyFn] - (envelopeId, nonce) => string
 */
export function createReplayGuard(redisClient, opts = {}) {
  const ttl = opts.ttlSeconds ?? 60;
  const keyFn =
    opts.keyFn ??
    ((envelopeId, nonce) => `nonce:${envelopeId}:${nonce}`);

  return async function replayGuard(req, res, next) {
    try {
      const { envelopeId, nonce } = req.body || {};
      if (!envelopeId || !nonce) {
        return res.status(400).json({ error: 'missing envelopeId or nonce' });
      }

      const key = keyFn(envelopeId, nonce);

      // node-redis v4 style; adapt if using a different client
      const result = await redisClient.set(key, '1', { NX: true, EX: ttl });

      if (result === null) {
        return res.status(409).json({ error: 'replay detected – nonce already used' });
      }

      return next();
    } catch (err) {
      console.error('replayGuard redis error', err);
      return res.status(500).json({ error: 'redis error' });
    }
  };
}

export default createReplayGuard;
