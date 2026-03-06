# German BGB Fragment

The `deontic-de-bgb` package encodes a fragment of the German Civil Code
(Bürgerliches Gesetzbuch) — specifically §104-§113 on legal capacity
(Geschäftsfähigkeit).

This package serves as a **validation of jurisdiction-agnosticism**: it
reuses the same `deontic-core` framework with the same layer tokens
(`Base`, `Proviso`, `SpecialRule`) to encode a completely different legal
system.

## Coverage

| Article | German | Korean Equivalent | Verdict |
|---------|--------|-------------------|---------|
| §104 | Geschäftsunfähigkeit | 행위무능력 | `Void` |
| §106 | Beschränkte Geschäftsfähigkeit | 제한능력 | `Voidable` |
| §107 | Einwilligung des Vertreters / rechtlicher Vorteil | 대리인 동의 / 순전한 이익 | `Valid` (proviso) |
| §110 | Bewirken der Leistung mit eigenen Mitteln (Taschengeldparagraph) | 용돈조항 | `Valid` (special rule) |

## Layer Stack

**Act type:** `CapacityAct` — **Layers:** `'[SpecialRule, Proviso, Base]`

```
SpecialRule (§110): Pocket money → Valid
    ↓ delegate
Proviso (§107): Purely beneficial or consent → Valid
    ↓ delegate
Base (§104/§106): Under 7 or permanently incapable → Void
                  Minor without consent → Voidable
                  Otherwise → Valid
```

## Types

```haskell
data CapacityAct = CapacityAct
  { caActor :: PersonId
  , caActId :: ActId
  }

data BGBFact
  = UnderSeven PersonId           -- §104 Nr. 1
  | PermanentlyIncapable PersonId -- §104 Nr. 2
  | IsMinor PersonId              -- §106
  | LegalRepConsent PersonId      -- §107 S. 1
  | PurelyBeneficial              -- §107 S. 1 Alt. 2
  | PocketMoney                   -- §110

data LimitedCapacity  -- domain-specific layer token
```

## Jurisdiction-Agnosticism Validation

The BGB encoding demonstrates that:

1. **Core layer tokens work cross-jurisdiction.** `Base`, `Proviso`, and
   `SpecialRule` from `deontic-core` apply to both Korean 민법 and German
   BGB without modification.

2. **Domain-specific tokens compose with core tokens.** `LimitedCapacity`
   is a BGB-specific layer token that fits naturally into the framework.

3. **The `Facts` type family handles different legal vocabularies.** Korean
   `CivilFact` and German `BGBFact` are completely separate types, each
   tailored to their legal system's concepts.

4. **The `Judgment` GADT is universal.** The same rendering and verdict
   extraction works for both jurisdictions.

## Test Coverage

9 tests covering all combinations of capacity, consent, purely beneficial
acts, and pocket money.
