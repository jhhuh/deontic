# Verdict Algebra

The `Verdict` type represents the four possible outcomes of legal
adjudication. The `verdictMeet` function defines a semilattice that
governs how independent verdicts combine.

## The Verdict Type

```haskell
data Verdict = Valid | Void | Voidable | Pending
  deriving (Eq, Ord, Show)
```

| Verdict | Korean | Meaning |
|---------|--------|---------|
| `Valid` | 유효 | The act is valid and effective |
| `Void` | 무효 | The act is void ab initio (from the beginning) |
| `Voidable` | 취소가능 | The act is valid until rescinded by the entitled party |
| `Pending` | 미확정 | The act's validity depends on a future event (e.g., ratification) |

## The Severity Ordering

$$\text{Void} > \text{Pending} > \text{Voidable} > \text{Valid}$$

This reflects legal severity. `Void` is the most severe (the act never had
legal effect); `Valid` is the least severe (no defect).

## The verdictMeet Semilattice

```haskell
verdictMeet :: Verdict -> Verdict -> Verdict
verdictMeet Valid b = b
verdictMeet a Valid = a
verdictMeet Void _ = Void
verdictMeet _ Void = Void
verdictMeet Pending _ = Pending
verdictMeet _ Pending = Pending
verdictMeet Voidable Voidable = Voidable
```

`verdictMeet` computes the **most severe** verdict from two independent
legal grounds. Its algebraic properties:

### Identity

$$\text{Valid} \sqcap a = a$$

A `Valid` finding doesn't affect the overall outcome.

### Absorption

$$\text{Void} \sqcap a = \text{Void}$$

If any ground yields `Void`, the entire act is void.

### Commutativity

$$a \sqcap b = b \sqcap a$$

The order in which independent issues are considered doesn't matter.

### Associativity

$$(a \sqcap b) \sqcap c = a \sqcap (b \sqcap c)$$

Grouping of independent issues doesn't matter.

!!! success "Verified"
    These properties are verified by:

    - **QuickCheck** over all $4^2 = 16$ (binary) and $4^3 = 64$ (ternary) cases
    - **Agda** exhaustive case analysis in `agda-sketch/Deontic.agda`

## Combining Independent Judgments

When multiple independent legal issues affect the same act, their verdicts
are combined using `verdictMeet` via `combineVerdicts`:

```haskell
combineVerdicts :: [SomeJudgment] -> Verdict
combineVerdicts = foldl' verdictMeet Valid . map (\(SomeJudgment j) -> verdict j)
```

### Example: Multi-Issue Dispute

A case involving a minor's unauthorized agency with fraud:

```haskell
let js = [ SomeJudgment minorJ     -- Voidable (§5: no consent)
         , SomeJudgment agencyJ    -- Pending  (§130: unauthorized)
         , SomeJudgment fraudJ     -- Voidable (§110: fraud)
         , SomeJudgment prescJ     -- Void     (§162: time-barred)
         ]
combineVerdicts js  -- => Void (prescription dominates)
```

The semilattice ensures that the most severe verdict prevails, regardless
of evaluation order.

## Why Not a Total Order?

One might ask: why a semilattice instead of just `max`? Because
`verdictMeet` is not simply the `Ord` ordering — it's a **meet** operation
on a lattice where `Valid` is the identity. This is semantically correct:
combining two `Valid` results gives `Valid` (identity), while combining
`Voidable` and `Pending` gives `Pending` (the more severe). The lattice
structure ensures these combinations are consistent and well-defined.
