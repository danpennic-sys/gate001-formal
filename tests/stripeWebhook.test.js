// tests/stripeWebhook.test.js
import express from 'express';
import request from 'supertest';
import { createStripeWebhook } from '../webhooks/stripe.js';

function makeApp({ constructEventImpl, onEventImpl }) {
  const stripe = {
    webhooks: {
      constructEvent: constructEventImpl,
    },
  };

  const onEvent = onEventImpl || (async () => {});

  const app = express();
  app.use('/webhook', createStripeWebhook(stripe, 'whsec_test', onEvent));
  return app;
}

describe('Stripe webhook', () => {
  test('valid signature and event → 200 + received', async () => {
    const fakeEvent = { id: 'evt_1', type: 'payment_intent.succeeded', data: {} };
    const constructEventImpl = jest.fn().mockReturnValue(fakeEvent);
    const onEventImpl = jest.fn().mockResolvedValue(undefined);

    const app = makeApp({ constructEventImpl, onEventImpl });

    const res = await request(app)
      .post('/webhook')
      .set('stripe-signature', 't=123,v1=abc')
      .set('Content-Type', 'application/json')
      .send(JSON.stringify({ id: 'evt_1' }));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ received: true });
    expect(constructEventImpl).toHaveBeenCalledTimes(1);
    expect(onEventImpl).toHaveBeenCalledWith(fakeEvent);
  });

  test('invalid signature → 400', async () => {
    const constructEventImpl = jest.fn().mockImplementation(() => {
      throw new Error('Invalid signature');
    });

    const app = makeApp({ constructEventImpl });

    const res = await request(app)
      .post('/webhook')
      .set('stripe-signature', 'bad')
      .set('Content-Type', 'application/json')
      .send('{}');

    expect(res.status).toBe(400);
    expect(res.text).toMatch(/Webhook Error/);
  });

  test('handler throws → 500', async () => {
    const fakeEvent = { id: 'evt_2', type: 'invoice.paid' };
    const constructEventImpl = jest.fn().mockReturnValue(fakeEvent);
    const onEventImpl = jest.fn().mockRejectedValue(new Error('meter down'));

    const app = makeApp({ constructEventImpl, onEventImpl });

    const res = await request(app)
      .post('/webhook')
      .set('stripe-signature', 't=123,v1=abc')
      .set('Content-Type', 'application/json')
      .send('{}');

    expect(res.status).toBe(500);
    expect(res.body.error).toBe('handler failed');
  });
});
