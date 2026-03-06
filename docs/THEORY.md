# Why This Works: Curry-Howard for Defeasible Deontic Logic

## The Problem

Curry-Howard isomorphism maps logical propositions to types and proofs to programs. But legal reasoning is **defeasible** — conclusions can be defeated by exceptions. A valid contract (proposition) becomes voidable if obtained by fraud (exception). Classical Curry-Howard can't model this because proofs are irrefutable.

Previous approaches either abandon type-level guarantees (Catala's runtime interpretation, SPINdle's Prolog-style resolution) or restrict to non-defeasible fragments (Pfenning-Davies modal logic).

## The Key Insight

GHC's typeclass instance resolution **is** a defeasibility resolver.

When GHC sees `adjudicate @MinorAct @'[Proviso, Base] act facts`, it resolves the instance for `(Proviso ': rest)`, which requires resolving the instance for `rest` (= `'[Base]`) via its context constraint. This is exactly the operational semantics of stratified defeasible logic:

1. Start at the highest-priority layer
2. Check if this layer applies (guards in the instance body)
3. If yes: **override** (construct `JOverride`)
4. If no: **delegate** to the next layer (construct `JDelegate`)
5. Bottom layer: **apply** the base rule (construct `JBase`)

The type-level list `'[Proviso, Base]` is the **strategy** — it determines which rules are consulted and in what order. The `Resolvable` type family pins this strategy per act type, and `query` uses it to fire the full resolution.

## Soundness Argument

**Claim:** If `query act facts` type-checks, the resulting `Judgment` value is a well-formed proof of the verdict under the applicable rules.

**Why:**

1. **Totality of the layer stack.** `Resolvable act` maps to a concrete type-level list. Each list element has a corresponding `Adjudicate` instance (or the program doesn't compile). An empty list `'[]` triggers `TypeError` — the "법의 흠결" (lacuna) is a *compile-time* error, not a runtime one.

2. **Structural induction on layers.** Each `Adjudicate act (l ': rest)` instance requires `Adjudicate act rest` in its context. GHC verifies this at compile time. The instance body must produce a `Judgment (l ': rest)`, which forces it to either:
   - `JOverride (prev :: Judgment rest) ...` — referencing the sub-proof
   - `JDelegate (prev :: Judgment rest)` — passing through the sub-proof

   In both cases, `prev` is obtained by calling `adjudicate @_ @rest`, which is the recursive resolution. The GADT constructor enforces that the layer structure matches.

3. **No instance overlap.** For a given `(act, layers)` pair, at most one instance matches (GHC's instance resolution is deterministic). Combined with the `TypeError` base case, resolution either succeeds uniquely or fails at compile time.

4. **Verdict extraction is total.** `verdict :: Judgment layers -> Verdict` pattern-matches on all three GADT constructors. Since `layers` is always non-empty (the `'[]` case is a type error), the function is total.

## What This Is Not

This is **not** a formal proof of soundness in the proof-theoretic sense. We don't have:
- A formal semantics for the deontic logic fragment we're encoding
- A proof that our encoding is faithful to that semantics
- A mechanized verification (e.g., in Agda or Coq)

What we do have is a **structural guarantee**: the Haskell type system ensures that every judgment has consulted every applicable layer in the correct order, and the reasoning chain is preserved in the proof term. This is stronger than any runtime system but weaker than a full formal verification.

## The Algebra of Verdicts

`verdictMeet` forms a **bounded semilattice** on `Verdict`:

- **Commutative:** `a ∧ b = b ∧ a` (order of independent queries doesn't matter)
- **Associative:** `(a ∧ b) ∧ c = a ∧ (b ∧ c)` (grouping doesn't matter)
- **Identity:** `Valid ∧ a = a` (valid doesn't affect other verdicts)
- **Absorbing:** `Void ∧ a = Void` (void dominates everything)

The ordering `Void > Pending > Voidable > Valid` reflects legal severity. When combining independent legal grounds (e.g., a contract that is both fraudulent and against public policy), the most severe verdict prevails.

These properties are verified by QuickCheck over all 4⁴ = 256 possible input combinations for the binary properties and 4³ = 64 triples for associativity.

## Comparison with Prior Art

| System | Defeasibility | Type Safety | Proof Terms | Rendering |
|--------|--------------|-------------|-------------|-----------|
| Catala | Runtime priorities | None (interpreted) | No | Built-in |
| SPINdle | Prolog resolution | None | Trace only | No |
| Pfenning-Davies | None (modal, not defeasible) | Full | Yes | No |
| **This work** | **GHC instance resolution** | **Type-level** | **Judgment GADT** | **Pluggable** |

The unique contribution is using an existing industrial-strength type system (GHC) as both the logic engine and the soundness checker, producing first-class proof terms that can be rendered as natural-language legal reasoning.

## Solved: Negation via Rebuttable Presumptions

The system now encodes negation/default reasoning through **rebuttable presumptions**. The pattern:

1. **Presumption layer** (base): asserts the default — e.g., §197 "점유자는 선의로 점유한 것으로 추정한다" → `Valid`
2. **Rebuttal layer** (override): checks for counter-evidence — e.g., `BadFaith ∈ facts` → `Voidable`
3. **Absence of rebuttal**: when no rebuttal facts are present, the override layer delegates to the presumption layer, and the default holds

This is a **closed-world assumption** encoded in open-world machinery: the absence of a fact in the `Set` is semantically meaningful. We don't need explicit negation-as-failure — the layer structure naturally handles "A is presumed unless B is proven" by making B's absence trigger delegation.

The `Presumption` and `Rebuttal` layer tokens are domain-specific (like `Ratification` and `ApparentAuth`), keeping the core framework unchanged.

## Solved: Temporal Reasoning via Heterogeneous Facts

The open `type family Facts act :: Type` enables temporal reasoning without changing the core framework. While most act types use `Set CivilFact` (atemporal boolean facts), `PrescriptionAct` uses a `PrescriptionFacts` record with numeric fields:

```haskell
data PrescriptionFacts = PrescriptionFacts
  { pfClaimDate     :: Day        -- 채권 발생일
  , pfCurrentDate   :: Day        -- 판단 시점
  , pfPeriodYears   :: Int        -- 소멸시효기간 (년)
  , pfInterruptedOn :: Maybe Day  -- 중단 시점
  }
type instance Facts PrescriptionAct = PrescriptionFacts
```

The layers encode the legal structure:
- **Expiration** (base, §162): `addGregorianYearsClip period claimDate <= currentDate → Void`
- **Interruption** (override, §174): recalculates from interruption date → `Valid` if within period

Date arithmetic uses `addGregorianYearsClip` from `Data.Time.Calendar`, implementing §157's calendar-year computation (역에 의한 계산). This correctly handles leap years — e.g., `2020-02-29 + 1년 = 2021-02-28`.

This demonstrates that the `Facts` type family is the escape hatch for richer fact structures. Any computable condition (time, arithmetic, external data) can be encoded as a domain-specific fact type without modifying the adjudication machinery.

## Solved: Quantification via Heterogeneous Facts

Universal quantification ("공유자 전원의 동의", §264) follows the same pattern as temporal reasoning: the open `Facts` type family carries structured data, and the instance body uses standard Haskell for the check:

```haskell
data CoOwnershipFacts = CoOwnershipFacts
  { cofOwners    :: [PersonId]
  , cofConsented :: Set PersonId
  }
type instance Facts CoOwnershipAct = CoOwnershipFacts

-- ∀ owner ∈ owners, owner ∈ consented
instance Adjudicate CoOwnershipAct '[Base] where
  adjudicate _ facts
    | all (`Set.member` cofConsented facts) (cofOwners facts) = JBase Valid ...
    | otherwise = JBase Void ...
```

The key insight: quantification doesn't need a new framework feature. The `Facts` type family + Haskell's own computation (`all`, `any`, `length`, arithmetic) handles boolean, temporal, and quantified conditions uniformly. The framework provides the *defeasibility structure*; the *domain logic* lives in the instance body.

## Formal Verification Sketch (Agda)

The core Judgment GADT and verdict algebra have been ported to Agda (`agda-sketch/Deontic.agda`). The key results:

1. **Verdict extraction is total.** The `verdict` function type-checks in Agda without absurd patterns or postulates, which constitutes a machine-checked proof of totality. The empty list case `'[]` is impossible by construction — all three GADT constructors require at least one layer.

2. **Verdict meet properties are proven.** Commutativity, identity (`Valid ⊓ a ≡ a`), and absorption (`Void ⊓ a ≡ Void`) are proven by exhaustive case analysis (4×4 = 16 cases for commutativity).

3. **The Judgment GADT ports directly.** The Agda encoding is structurally identical to the Haskell one — `JBase`, `JOverride`, `JDelegate` with the same type indices. This validates the claim that the Haskell encoding is a faithful Curry-Howard representation.

What the sketch does NOT prove: faithfulness of the encoding to a formal deontic logic semantics. That would require first formalizing the semantics, which is future work.

## Open Questions

1. **Formal deontic semantics.** The Agda sketch proves structural properties (totality, algebra). A deeper formalization would define a denotational semantics for stratified defeasible deontic logic and prove that the Judgment GADT is a sound and complete representation.
