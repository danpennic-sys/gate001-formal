// webhooks/stripe.js
import express from 'express';

/**
 * Creates a Stripe webhook router.
 * @param {object} stripe - Stripe SDK instance (or mock)
 * @param {string} endpointSecret - webhook signing secret
 * @param {function} onEvent - async (event) => void
 */
export function createStripeWebhook(stripe, endpointSecret, onEvent) {
  const router = express.Router();

  router.post(
    '/',
    express.raw({ type: 'application/json' }),
    async (req, res) => {
      const sig = req.headers['stripe-signature'];
      let event;

      try {
        event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
      } catch (err) {
        console.error('Stripe signature verification failed', err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
      }

      try {
        await onEvent(event);
        res.json({ received: true });
      } catch (err) {
        console.error('Stripe event handler error', err);
        res.status(500).json({ error: 'handler failed' });
      }
    }
  );

  return router;
}

export default createStripeWebhook;
