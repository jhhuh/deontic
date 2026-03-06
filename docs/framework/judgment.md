# Judgment GADT & Layers

The `Judgment` GADT is the proof term of our system — a data structure
that records the full reasoning chain from base rule through all override
layers.

## The GADT

```haskell
data Judgment (layers :: [Type]) where
  JBase     :: Verdict -> ArticleRef -> Text -> Judgment '[l]
  JOverride :: Judgment prev -> Verdict -> ArticleRef -> Text
            -> Judgment (l ': prev)
  JDelegate :: Judgment prev -> Judgment (l ': prev)
```

### Constructors

**`JBase`** — A base-layer judgment. The bottom of the stack; no further
delegation. Contains the verdict, the statutory reference, and the
reasoning text.

```haskell
JBase Valid (ArticleRef "민법" 5 (Just 1))
  "법정대리인의 동의를 얻어 법률행위가 유효하다."
```

**`JOverride`** — An override. This layer consulted the lower layers
(stored in `prev`) and decided to override their verdict.

```haskell
JOverride prevJudgment Valid (ArticleRef "민법" 5 (Just 1))
  "권리만을 얻는 행위이므로 동의 없이도 유효하다."
```

**`JDelegate`** — A pass-through. This layer had no opinion and delegated
entirely to the lower layers.

```haskell
JDelegate prevJudgment
```

### Type-Level Guarantees

The `layers` type parameter ensures structural correctness:

- `JBase` produces `Judgment '[l]` — exactly one layer
- `JOverride` and `JDelegate` produce `Judgment (l ': prev)` — adding one layer on top
- The `prev` in `JOverride`/`JDelegate` has type `Judgment prev` — the sub-proof

This means:

1. **Layer count matches.** A 3-layer stack produces a `Judgment` with exactly 3 layers in its type.
2. **No orphan overrides.** An override always references the sub-proof it overrides.
3. **No fabricated delegations.** A delegation always carries the delegated-to judgment.

## Verdict Extraction

```haskell
verdict :: Judgment layers -> Verdict
verdict (JBase v _ _)       = v
verdict (JOverride _ v _ _) = v
verdict (JDelegate prev)    = verdict prev
```

`verdict` extracts the final verdict — the topmost non-delegated verdict.
It is **total** (pattern-matches all constructors) — this is verified by
the [Agda sketch](../verification/index.md).

## Layer Tokens

Layers are uninhabited types used as type-level tags:

### Core Tokens (deontic-core)

| Token | Korean | Meaning |
|-------|--------|---------|
| `Base` | 원칙 | General rule |
| `Proviso` | 단서 | Proviso/exception |
| `SpecialRule` | 특칙 | Lex specialis |

### Domain Tokens (deontic-kr-civil)

| Token | Korean | Meaning | Articles |
|-------|--------|---------|----------|
| `Ratification` | 추인 | Principal's ratification | §130, §132 |
| `ApparentAuth` | 표현대리 | Apparent authority | §125-129 |
| `Presumption` | 추정 | Rebuttable presumption (default) | §197, §200 |
| `Rebuttal` | 반증 | Rebuttal of presumption | §197, §200 |
| `Expiration` | 시효만료 | Prescription expiration | §162 |
| `Interruption` | 시효중단 | Prescription interruption | §168, §174 |
| `ContributoryNeg` | 과실상계 | Contributory negligence | §763→§396 |
| `FormException` | 등기예외 | Exception to formality | §187 |
| `ShortPrescription` | 단기시효 | Short acquisitive prescription | §245② |
| `CreditorDefense` | 채권자과실 | Creditor's own fault defense | §390 |
| `BuyerKnowledge` | 매수인악의 | Buyer knew of defect | §580② |
| `RenewalRight` | 묵시적갱신 | Implicit lease renewal | §639 |

## Step Extraction

The `Deontic.Render` module extracts steps from a judgment:

```haskell
data Step = Step
  { stepKind       :: StepKind   -- Applied | Overridden | Delegated
  , stepVerdict    :: Verdict
  , stepArticle    :: ArticleRef
  , stepSourceText :: Text
  }

judgmentSteps :: Judgment layers -> [Step]
```

This converts the recursive GADT into a flat list of reasoning steps,
bottom-up. `JDelegate` constructors are omitted from the output (they
carry no independent reasoning).

## Example: Full Reasoning Chain

For an unauthorized agency act (§130) with ratification:

```haskell
let j = query (UnauthAgencyAct principal agent actId)
              (Set.singleton Ratified)
```

The judgment structure:

```
JDelegate                              -- ApparentAuth: no apparent authority facts
  (JOverride                           -- Ratification: Ratified ∈ facts → Valid
    (JBase Pending ...)                -- Base: unauthorized → Pending
    Valid
    (ArticleRef "민법" 132 Nothing)
    "본인이 추인하여 유권대리와 동일한 효력이 생겼다.")
```

Steps extracted:

1. `Applied` — §130: base rule, verdict `Pending` (unauthorized agent)
2. `Overridden` — §132: ratification overrides to `Valid`

Note: the `ApparentAuth` layer delegated (no apparent authority facts), so
it doesn't appear in the steps.
