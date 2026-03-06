# 총칙 Remainder (§134–§161) Design

## Goal

Complete 총칙 (General Provisions) coverage by encoding §134–§161: unauthorized agency remedies, invalidity meta-rules, cancellation/ratification of voidable acts, and conditional juristic acts.

## Scope

- **12 articles** with verdict logic out of 28 total (§134–§161)
- **7 computational articles** (§155–§161) already implemented via `addGregorianYearsClip`
- **8 procedural/definitional articles** skipped (§136, §140, §142, §144, §149, §153, §154, §155)
- §146 already encoded as `RescissionAct`

## Architecture

### Four new modules

| Module | Act Types | Articles | Layers |
|--------|-----------|----------|--------|
| `AgencyRemedies.hs` | `AgencyWithdrawalAct`, `AgentLiabilityAct` | §134, §135 | `CounterpartyKnowledge`, `Proviso` |
| `Invalidity.hs` | `PartialInvalidityAct` | §137–§139 | `Conversion`, `HypotheticalIntent`, `Base` |
| `Cancellation.hs` | `CancellableAct` (wrapper) | §141, §143–§145 | `ConstructiveRatification`, `GeneralRatification`, `Base` |
| `ConditionalAct.hs` | `ConditionalAct` | §147, §150–§152 | `BadFaithCondition`, `IllegalCondition`, `Base` |

### Key design decisions

1. **Meta-rules as layers** — §137–§139 and §141–§145 operate on prior judgment outputs. Encoded as layers on wrapper act types rather than standalone meta-functions.

2. **`CancellableAct` wrapper pattern** — takes a `caPriorVerdict :: Verdict` from a previous `query` call. This separates the base validity question from the cancellation/ratification meta-question.

3. **ADT for condition state** — `ConditionState = CondPending | CondFulfilled | CondImpossible | CondIllegal` prevents invalid fact combinations (mutually exclusive states).

4. **Separate agency remedy act types** — §134 (withdrawal right) and §135 (agent liability) are different legal questions from §130 (act validity), so they get their own act types.

## New Types

### Fact records

```haskell
data PartialInvalidityFacts = PartialInvalidityFacts
  { pifPartVoid            :: Bool
  , pifHypotheticalIntent  :: Bool
  , pifMeetsOtherReqs      :: Bool
  , pifConversionIntent    :: Bool
  , pifRatifiedWithKnowledge :: Bool
  }

data CancellationFacts = CancellationFacts
  { cnfCancelled           :: Bool
  , cnfRatified            :: Bool
  , cnfCauseCeased         :: Bool
  , cnfRatifierIsGuardian  :: Bool
  , cnfConstructive        :: Maybe ConstructiveRatificationEvent
  , cnfObjectionReserved   :: Bool
  }

data ConditionalFacts = ConditionalFacts
  { condType     :: ConditionType
  , condState    :: ConditionState
  , condBadFaith :: Maybe BadFaithKind
  }
```

### ADTs

```haskell
data ConditionType = Suspensive | Resolutive | StartDate | EndDate
data ConditionState = CondPending | CondFulfilled | CondImpossible | CondIllegal
data BadFaithKind = BadFaithPrevention | BadFaithCausation
data ConstructiveRatificationEvent
  = FullOrPartialPerformance | DemandForPerformance | Novation
  | SecurityProvision | RightAssignment | CompulsoryExecution
```

### New layer tokens

```haskell
data CounterpartyKnowledge   -- §134 상대방 악의
data HypotheticalIntent      -- §137 단서 가정적 의사
data Conversion              -- §138 무효행위의 전환
data GeneralRatification     -- §143 취소할 수 있는 행위의 추인
data ConstructiveRatification -- §145 법정추인
data IllegalCondition        -- §151 불법조건/기성조건
data BadFaithCondition       -- §150 반신의행위
```

## Layer Logic

### AgencyWithdrawalAct `'[CounterpartyKnowledge, Base]`

- Base: Valid (withdrawal permitted)
- CounterpartyKnowledge: counterparty knew → Void (no withdrawal right)

### AgentLiabilityAct `'[Proviso, Base]`

- Base: Void (agent liable)
- Proviso: counterparty knew/could have known OR agent limited-capacity → Valid (no liability)

### PartialInvalidityAct `'[Conversion, HypotheticalIntent, Base]`

- Base (§137): part void → Void; otherwise → Valid
- HypotheticalIntent (§137 단서, §139): hypothetical intent → Valid; ratified with knowledge → Valid
- Conversion (§138): meets other requirements + conversion intent → Valid

### CancellableAct `'[ConstructiveRatification, GeneralRatification, Base]`

- Base (§141): prior Voidable + cancelled → Void; non-Voidable → delegate
- GeneralRatification (§143–§144): ratified + (cause ceased OR guardian) → Valid
- ConstructiveRatification (§145): constructive event + no objection → Valid

### ConditionalAct `'[BadFaithCondition, IllegalCondition, Base]`

- Base (§147/§152): truth table by condition type × fulfillment state
- IllegalCondition (§151): illegal → Void; impossible/already-fulfilled truth table
- BadFaithCondition (§150): prevention → deemed fulfilled; causation → deemed unfulfilled

## Testing

~36 new tests across 4 test files, bringing total from 166 to ~202.

## Not encoded

- §136 (scoping rule for unilateral acts)
- §140 (standing — who may cancel)
- §142 (procedure — how to cancel)
- §144 (timing precondition — folded into GeneralRatification layer guard)
- §149 (definitional — conditional rights are transferable)
- §153 (presumption about time limit benefit)
- §154 (cross-reference)
- §155–§161 (computation rules — already implemented)
