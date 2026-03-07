# deontic-temporal

Temporal reasoning for the [Deotonic](https://github.com/jhhuh/deontic) legal logic framework.

## What This Solves

Legal rules are not eternal. Statutes get amended, enforcement decrees (시행령) change thresholds and rates, and the correct legal judgment depends on *when* an act occurred. This package provides:

- **Point-in-time rule resolution** — given a date, find the applicable version of each rule
- **Temporal override integration** — amendment versions plug into the existing defeasible reasoning engine as time-conditioned layers
- **Timeline data structures** — ordered version histories for provisions that change frequently

## Example

```haskell
-- 이자제한법시행령 §2①: maximum interest rate over time
maxInterestRates :: Timeline InterestAct
maxInterestRates = timeline
  [ (fromGregorian 2007  6 30, Just (fromGregorian 2014 1 13), rate 30)
  , (fromGregorian 2014  1 14, Just (fromGregorian 2018 2  7), rate 25)
  , (fromGregorian 2021  7  7, Nothing,                        rate 20)
  ]

-- Evaluate with a specific date
evaluate :: Day -> InterestAct -> Judgment ...
```

## Status

Early design phase. Incubated inside [jhhuh/deontic](https://github.com/jhhuh/deontic) as a subdirectory.

## Origin

Motivated by the need to encode Korean enforcement decrees (시행령) which are "full of overriding" — frequent amendments creating towers of temporal overrides that the base framework's eternal-rule model cannot represent.
