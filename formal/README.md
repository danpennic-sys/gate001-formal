# ContinuityV041 – Formal Verification

## Spec
- `ContinuityV041.tla` – event continuity model with arbitration, lineage, and bounded meter
- `ContinuityV041.cfg` – model parameters and invariants

## Key modelling decisions
- `MaxEvents = 4` bounds the state space for exhaustive checking
- `Stutter == UNCHANGED vars` allows graceful idleness after the bound (no artificial deadlock)
- `OpenArbitration` quantifiers are domain-tightened to reduce state explosion
- Invariants checked: `Valid`, `EpochBounded`

## Run TLC
```bash
java -XX:+UseParallelGC -jar tla2tools.jar \
  -config ContinuityV041.cfg ContinuityV041.tla
```

Or with the official image:
```bash
docker run --rm -v $PWD:/spec tlaplus/tlaplus \
  tlc2.TLC -config /spec/formal/ContinuityV041.cfg /spec/formal/ContinuityV041.tla
```

## Last verified result
See `artifacts/tlc/ContinuityV041.tlc.log`.

- 1 630 762 states generated
- 815 381 distinct states
- Depth 5
- No errors found
- Fingerprint collision probability ≈ 10⁻⁷

This log was produced from the exact `.tla` / `.cfg` pair in this directory.
