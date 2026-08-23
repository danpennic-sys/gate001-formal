# gate001-formal

Gate 001 formal verification package and supporting stubs.

## Formal verification
See `formal/README.md` and `artifacts/tlc/ContinuityV041.tlc.log`.

TLC result (exact pair in this repo):
- 1 630 762 states generated
- 815 381 distinct states
- Depth 5
- No errors

## Stubs
- `middleware/replayGuard.js` – injectable Redis SET NX EX guard
- `webhooks/stripe.js` – injectable Stripe webhook router (raw body)
- `tests/` – Jest tests for the above

## Security
No production secrets are committed. Use the secret-scan script before push:

```bash
bash gate001/secret-scan.sh
```
