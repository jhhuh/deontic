# Defeasibility Patterns Catalog

This page catalogs the recurring patterns used across the 민법 encoding.
Each pattern is a reusable strategy for encoding a particular kind of
legal defeasibility.

## Pattern 1: 단서 Override (Proviso)

**Structure:** `'[Proviso, Base]`

The simplest pattern. A base rule establishes the default; a proviso
overrides it when an exception applies.

**Examples:**

- §5 미성년자: consent required (base) → rights-only acts exempt (proviso)
- §108 통정허위표시: sham → void (base) → bona fide third party protected (proviso)
- §109 착오: mistake → voidable (base) → gross negligence blocks rescission (proviso)

```
Base:    if condition → Verdict₁
Proviso: if exception → JOverride prev Verdict₂
         else         → JDelegate prev
```

## Pattern 2: 3-Layer Stack

**Structure:** `'[SpecialRule, Proviso, Base]`

For graduated defeasibility where multiple levels of override exist.

**Example:** §103-110 법률행위

- Base: contra bonos mores / exploitative → `Void`
- Proviso: hidden intention rules
- SpecialRule: mistake / fraud rules

## Pattern 3: Rebuttable Presumption

**Structure:** `'[Rebuttal, Presumption]`

For legal presumptions that hold unless counter-evidence is presented.
The key insight: **absence of rebuttal facts triggers delegation** to
the presumption, which defaults to `Valid`.

**Example:** §197, §200 점유 추정

```
Presumption (base): always → JBase Valid
Rebuttal (override): if counter-evidence → JOverride Voidable
                     else               → JDelegate (presumption holds)
```

This is a **closed-world assumption** in open-world machinery. The absence
of a fact in the `Set` is semantically meaningful.

## Pattern 4: Lex Specialis

**Structure:** `'[FormException, Base]` (or `'[SpecialRule, Base]`)

A special rule overrides a general rule for specific cases.

**Example:** §186-188 물권변동

- Base (§186): real property requires registration
- FormException (§187): inheritance/court order/auction bypass registration

```
Base:          general rule → Verdict
FormException: if special case → JOverride prev Valid
               else           → JDelegate prev
```

## Pattern 5: Temporal Reasoning

**Structure:** `'[Interruption, Expiration]` or `'[Base]`

For time-based legal effects using calendar dates.

**Examples:**

- §162 소멸시효: `claimDate + period <= currentDate` → expired
- §146 제척기간: `actDate + 10years <= currentDate` → right extinguished
- §245 취득시효: `startDate + 20years <= currentDate` → ownership acquired

All use `Data.Time.Day` with `addGregorianYearsClip` per §157.

## Pattern 6: Verdict-Conditional Override

**Structure:** `'[Defense, Base]`

The override layer inspects `verdict prev` before deciding whether to
fire. Only overrides when the base verdict meets a condition.

**Examples:**

- §396 과실상계: only when `verdict prev == Void` (liability exists)
- §390 채권자과실: only when `verdict prev == Void` (debtor liable)
- §580② 매수인 악의: only when `verdict prev /= Valid` (warranty exists)

```haskell
instance ... => Adjudicate act (Defense ': rest) where
  adjudicate act facts
    | defenseCondition facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =       -- ← conditional on base verdict
        JOverride prev Voidable ...
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
```

!!! warning "Why not always override?"
    If the base verdict is `Valid` (no liability), there's nothing to
    defend against. Applying a defense to a `Valid` verdict would be
    semantically wrong — you can't reduce zero liability.

## Pattern 7: Graduated Override

**Structure:** `'[ShortPrescription, Base]`

The override has stricter requirements but more favorable terms.

**Example:** §245 취득시효

- Base (§245①): 20 years, basic requirements → ownership
- ShortPrescription (§245②): 10 years, but needs good faith + no negligence

## Pattern 8: Multi-Condition Override

**Structure:** `'[RenewalRight, Base]`

The override requires a conjunction of multiple conditions.

**Example:** §639 묵시적 갱신

```haskell
| lfPeriodExpired facts     -- 기간 만료 AND
, lfContinuedUse facts      -- 계속 사용 AND
, lfNoObjection facts        -- 이의 없음 AND
, not (lfTwoRentsLate facts) -- 2기 연체 아님
= JOverride prev Valid ...
```

All four conditions must hold simultaneously.

## Pattern 9: Wrapper Pattern (Second-Order Verdict)

**Structure:** `'[ConstructiveRatification, GeneralRatification, Base]`

A **second-order** use of the framework: the act type takes a prior `Verdict`
(output of a previous `query` call) as an input field. This enables meta-rules
that operate on the result of other legal evaluations.

**Example:** §141-145 취소 (CancellableAct)

```haskell
data CancellableAct = CancellableAct
  { caActId        :: ActId
  , caPriorVerdict :: Verdict   -- ← output of a previous query
  }
```

The Base layer inspects `caPriorVerdict`:

```haskell
instance Adjudicate CancellableAct '[Base] where
  adjudicate act facts
    | caPriorVerdict act /= Voidable = JBase (caPriorVerdict act) ...
    --  ^ non-voidable acts pass through unchanged
    | cnfCancelled facts = JBase Void ...
    | otherwise          = JBase Voidable ...
```

Override layers then apply ratification rules (§143 general, §145 constructive)
that can restore a cancelled-Void back to Valid.

!!! note "Why a wrapper, not a combined stack?"
    The base validity question ("is this act voidable?") and the cancellation
    meta-question ("was the voidable act cancelled or ratified?") are
    **separate legal evaluations**. The wrapper pattern keeps them decoupled —
    you can swap out the inner evaluation without touching the cancellation logic.

## Pattern 10: Deemed Fulfillment (Recursive Query)

**Structure:** `'[BadFaithCondition, IllegalCondition, Base]`

The most sophisticated pattern: an `Adjudicate` instance calls `query`
recursively with **modified facts** to evaluate a counterfactual scenario.
This encodes §150 (반신의행위) — if a party prevents a condition from being
fulfilled in bad faith, the condition is **deemed fulfilled**.

**Example:** §150 반신의행위 (ConditionalAct)

```haskell
instance Adjudicate ConditionalAct rest
      => Adjudicate ConditionalAct (BadFaithCondition ': rest) where
  adjudicate act facts = case condBadFaith facts of
    Just BadFaithPrevention ->
      let deemedFacts = facts { condState = CondFulfilled
                              , condBadFaith = Nothing }  -- ← removes trigger
          deemedResult = query act deemedFacts             -- ← recursive query
      in JOverride (adjudicate @_ @rest act facts)
                   (verdict deemedResult) ...
    Nothing -> JDelegate (adjudicate @_ @rest act facts)
```

The recursive `query` re-evaluates the act as if the condition were fulfilled,
then uses that counterfactual verdict as the override verdict.

### Safety Analysis

**Is the recursive `query` safe?** Yes, with a caveat:

1. **Termination guarantee:** Setting `condBadFaith = Nothing` removes the only
   trigger for the `BadFaithCondition` layer. On re-entry, `Nothing` matches
   the catch-all → `JDelegate` → no further recursion. Maximum depth: **1**.

2. **No shared state:** `query` is pure — no mutation, no side effects. The
   modified facts are a local copy.

3. **Fragility risk:** The termination guarantee is a **convention**, not a
   compile-time invariant. A future developer adding a new trigger to
   `BadFaithCondition` could break the depth bound. Consider:
    - Documenting the recursion contract in the module
    - Adding a depth counter to `ConditionalFacts` as a safety net (not currently needed)

!!! warning "Not infinitely composable"
    Unlike Patterns 1-8, this pattern does **not** compose arbitrarily. Nesting
    two recursive-query patterns could create mutual recursion. Currently safe
    because `ConditionalAct` is the only act type using this pattern.

## Pattern Composition

These patterns compose naturally. A multi-issue case study might combine:

```haskell
let js = [ SomeJudgment $ query minorAct    facts₁  -- Pattern 1 (proviso)
         , SomeJudgment $ query agencyAct   facts₂  -- Pattern 2 (3-layer)
         , SomeJudgment $ query prescAct    facts₃  -- Pattern 5 (temporal)
         , SomeJudgment $ query tortAct     facts₄  -- Pattern 6 (conditional)
         ]
combineVerdicts js  -- verdictMeet semilattice combines them
```

The `verdictMeet` semilattice ensures that the most severe verdict from
any independent issue prevails, regardless of evaluation order.
