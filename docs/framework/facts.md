# Facts Type Family

The `Facts` type family is the key extensibility mechanism for domain-specific
evidence. It allows each act type to define its own fact structure without
modifying the core framework.

## The Type Family

```haskell
type family Facts act :: Type
```

This is an **open** type family — new instances can be added by any module.
The framework never inspects the structure of `Facts act`; it only threads
it through to the `Adjudicate` instances.

## Fact Type Strategies

### Strategy 1: Set of Flags (`Set CivilFact`)

For acts where evidence is a collection of boolean conditions:

```haskell
data CivilFact
  = IsMinor PersonId
  | HasConsent PersonId ActId
  | MerelyAcquiresRight
  | ContraBonorsMores
  | ...
  deriving (Eq, Ord, Show)

type instance Facts MinorAct    = Set CivilFact
type instance Facts JuristicAct = Set CivilFact
type instance Facts ShamAct     = Set CivilFact
```

**Used by:** §5 (persons), §103-110 (juristic acts), §114-132 (agency),
§186-188 (property transfer), §197-200 (possession presumptions)

**Advantages:**

- Simple: `Set.member fact facts` checks presence
- Composable: `Set.fromList [fact1, fact2, ...]` builds evidence
- Shared vocabulary: multiple act types use the same `CivilFact` constructors

### Strategy 2: Domain-Specific Records

For acts with structured, non-boolean evidence:

```haskell
data PrescriptionFacts = PrescriptionFacts
  { pfClaimDate     :: Day        -- 채권 발생일
  , pfCurrentDate   :: Day        -- 판단 시점
  , pfPeriodYears   :: Int        -- 소멸시효기간 (년)
  , pfInterruptedOn :: Maybe Day  -- 중단 시점
  }

type instance Facts PrescriptionAct = PrescriptionFacts
```

**Used by:**

| Record Type | Act Type | Fields |
|-------------|----------|--------|
| `PrescriptionFacts` | `PrescriptionAct` | Dates, period, interruption |
| `RescissionFacts` | `RescissionAct` | Knowledge date, act date, current date |
| `AcqPrescFacts` | `AcqPrescriptionAct` | Start date, current date, good faith, etc. |
| `CoOwnershipFacts` | `CoOwnershipAct` | Owner list, consent set |
| `TortFacts` | `TortAct` | Fault, unlawfulness, damage, causation, victim neg |
| `DefaultFacts` | `DefaultAct` | Due, non-performance, fault, impossibility |
| `WarrantyFacts` | `WarrantyAct` | Defect, significance, buyer knowledge, notice |
| `LeaseFacts` | `LeaseAct` | Contract, rent, expiry, continued use, objection |

**Advantages:**

- Type-safe field access
- Richer structure (dates, lists, Maybe values)
- Self-documenting: field names describe the legal elements

## Calendar Year Computation (§157)

Temporal fact types use `Data.Time.Day` with `addGregorianYearsClip` for
proper calendar year computation per 민법 §157:

> "기간을 연으로 정한 때에는 역에 의하여 계산한다."
> (When a period is defined in years, it is computed by the calendar.)

```haskell
-- §162: Has the prescription period expired?
addGregorianYearsClip (toInteger (pfPeriodYears facts)) (pfClaimDate facts)
  <= pfCurrentDate facts
```

This correctly handles leap years: `2020-02-29 + 1년 = 2021-02-28`
(via `addGregorianYearsClip`'s clipping behavior).

## The Quantification Pattern

The `Facts` type family enables universal quantification without any
framework changes. For §264 (co-ownership requires unanimous consent):

```haskell
data CoOwnershipFacts = CoOwnershipFacts
  { cofOwners    :: [PersonId]
  , cofConsented :: Set PersonId
  }

instance Adjudicate CoOwnershipAct '[Base] where
  adjudicate _ facts
    | all (`Set.member` cofConsented facts) (cofOwners facts) =
        JBase Valid ...
    | otherwise =
        JBase Void ...
```

The `all` function + `Set.member` implements $\forall\, \text{owner} \in
\text{owners},\; \text{owner} \in \text{consented}$ using standard Haskell.
The framework provides the defeasibility structure; domain logic lives in
the instance body.

## Design Philosophy

The `Facts` type family embodies a key principle: **the framework should
provide the minimum abstraction necessary**.

It doesn't prescribe how evidence should be structured. It doesn't require
a canonical fact representation. It just says: "for each act type, you
tell me what evidence looks like, and I'll thread it through."

This is why the framework needed zero changes to support temporal reasoning
(dates), quantification (lists), or structured conditions (records). The
`Facts` type family is the escape hatch that makes it all possible.
