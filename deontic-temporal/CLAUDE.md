# deontic-temporal

Temporal reasoning layer for the Deotonic framework — handles time-dependent legal rules, statutory amendments, and enforcement decree (시행령) versioning.

## Problem

Legal rules have effective dates. A single provision may have 10+ versions over its lifetime (especially 시행령). The current Deotonic framework treats rules as eternal. This package adds the temporal dimension.

## Directory Layout

```
deontic-temporal/
  CLAUDE.md              # this file
  README.md              # standalone description
  artifacts/
    devlog.md            # design decisions, append-only
    logs/                # test/build output
  tests/                 # test files
  src/                   # Haskell source (Deontic.Temporal.*)
```

## Architecture

Two layers of temporal handling:

1. **Type-level (structural)**: statute → exception → counter-exception (existing Judgment GADT)
2. **Value-level (parametric)**: `TemporalRule` timelines — which version's thresholds apply on a given date

The type-level stack handles legal *structure*. The value-level timeline handles *parameter churn* (rates, thresholds, ages) that changes with every 시행령 amendment.

Key types:
- `TemporalRule a` — a rule version with effective/expiry dates
- `Timeline a` — ordered list of `TemporalRule a` for one provision
- `cfDate :: Day` added to `CaseFacts` — when the legal act occurred

## Conventions

- Haskell, GHC 9.6.7, same as parent project
- Module namespace: `Deontic.Temporal.*`
- Tests: HSpec, same pattern as `deontic-core` and `deontic-kr-civil`
- Commits: write as if this directory is the repo root

## Parent Project

This is incubated inside [jhhuh/deontic](https://github.com/jhhuh/deontic). Designed for `git subtree split` extraction when mature.

## Current Status

Scaffolding only. See `artifacts/devlog.md` for design history.
