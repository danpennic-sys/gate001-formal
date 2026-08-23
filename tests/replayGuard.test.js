// tests/replayGuard.test.js
import express from 'express';
import bodyParser from 'body-parser';
import request from 'supertest';
import redisMock from 'redis-mock';
import { createReplayGuard } from '../middleware/replayGuard.js';

function promisifyRedis(client) {
  return {
    set(key, value, options) {
      return new Promise((resolve, reject) => {
        const args = [key, value];
        if (options?.NX) args.push('NX');
        if (options?.EX) args.push('EX', options.EX);
        client.set(...args, (err, reply) => {
          if (err) return reject(err);
          resolve(reply === 'OK' ? 'OK' : null);
        });
      });
    },
  };
}

function makeApp(redis) {
  const app = express();
  app.use(bodyParser.json());
  app.post('/test', createReplayGuard(redis), (req, res) => {
    res.status(200).json({ ok: true });
  });
  return app;
}

describe('replayGuard (real middleware)', () => {
  test('first request with nonce succeeds, second is rejected', async () => {
    const raw = redisMock.createClient();
    const redis = promisifyRedis(raw);
    const app = makeApp(redis);
    const payload = { envelopeId: 'env1', nonce: 'n1' };

    const r1 = await request(app).post('/test').send(payload);
    expect(r1.status).toBe(200);
    expect(r1.body).toEqual({ ok: true });

    const r2 = await request(app).post('/test').send(payload);
    expect(r2.status).toBe(409);
    expect(r2.body.error).toMatch(/replay detected/);
  });

  test('missing envelopeId or nonce returns 400', async () => {
    const raw = redisMock.createClient();
    const redis = promisifyRedis(raw);
    const app = makeApp(redis);

    const r = await request(app).post('/test').send({ envelopeId: 'x' });
    expect(r.status).toBe(400);
  });
});
