# deontic-temporal devlog

## 2026-03-07: Project inception

**Why this exists**: The Deotonic framework encodes Korean Civil Act (민법) provisions as type-level defeasible rules. When we tried to extend coverage to enforcement decrees (시행령), we hit a fundamental gap: rules have effective dates, and 시행령 provisions change frequently (interest rate caps, deposit thresholds, age definitions). The current framework treats rules as eternal.

**User observation**: "시행령 is full of overriding" — a single provision can have 10+ temporal versions. Type-level layers don't scale to this kind of churn.

**Design direction agreed**:

1. Add `cfDate :: Day` to `CaseFacts` — the date the legal act occurred
2. Two-tier temporal model:
   - **Type-level** (existing): structural legal reasoning (statute → exception → counter-exception)
   - **Value-level** (new): `TemporalRule` / `Timeline` for parametric churn (rates, thresholds)
3. Temporal layers in the type stack delegate to value-level timelines
4. Point-in-time resolution only (not bi-temporal) as first step

**Key design question deferred**: Whether to support bi-temporal reasoning (act date + knowledge date) for retroactive amendments. Starting with point-in-time.

**Concrete motivating examples**:
- 민법 §5: 미성년자 age changed from 20→19 (2013-07-01)
- 이자제한법시행령 §2①: max interest rate 30%→25%→20% over time
- 주택임대차보호법시행령: deposit thresholds change by region and year
