# Formal Verification (Agda Sketch)

The `agda-sketch/Deontic.agda` file contains a partial formalization of
the core framework in Agda, providing machine-checked proofs of key
structural properties.

## What Is Verified

### 1. Verdict Extraction Is Total

The `verdict` function in Agda type-checks without absurd patterns or
postulates. Since Agda requires **total** functions by default, this
constitutes a machine-checked proof that verdict extraction handles all
possible `Judgment` values.

```agda
verdict : ∀ {ls} → Judgment ls → Verdict
verdict (jbase v _ _)       = v
verdict (joverride _ v _ _) = v
verdict (jdelegate prev)    = verdict prev
```

The empty list case `'[]` is impossible by construction — all three GADT
constructors require at least one layer in the type index.

### 2. Verdict Meet Algebra

The following properties of `verdictMeet` are proven by exhaustive case
analysis:

**Commutativity:** $a \sqcap b = b \sqcap a$

```agda
meet-comm : ∀ (a b : Verdict) → verdictMeet a b ≡ verdictMeet b a
meet-comm valid    valid    = refl
meet-comm valid    void     = refl
-- ... (16 cases, all by refl)
```

**Identity:** $\text{Valid} \sqcap a = a$

```agda
meet-identity : ∀ (a : Verdict) → verdictMeet valid a ≡ a
meet-identity valid     = refl
meet-identity void      = refl
meet-identity voidable  = refl
meet-identity pending   = refl
```

**Absorption:** $\text{Void} \sqcap a = \text{Void}$

```agda
meet-absorb : ∀ (a : Verdict) → verdictMeet void a ≡ void
meet-absorb valid    = refl
meet-absorb void     = refl
meet-absorb voidable = refl
meet-absorb pending  = refl
```

### 3. Judgment GADT Structural Fidelity

The Agda encoding is structurally identical to the Haskell one:

```agda
data Judgment : List Set → Set where
  jbase     : Verdict → ArticleRef → String → Judgment (l ∷ [])
  joverride : Judgment rest → Verdict → ArticleRef → String
            → Judgment (l ∷ rest)
  jdelegate : Judgment rest → Judgment (l ∷ rest)
```

This validates that the Haskell `Judgment` GADT is a faithful Curry-Howard
representation — the same structure type-checks in a dependently-typed
proof assistant.

## What Is NOT Verified

!!! warning "Limitations"
    The Agda sketch does **not** prove:

    - **Faithfulness to a formal deontic semantics.** We don't have a
      denotational semantics for stratified defeasible deontic logic to
      prove faithfulness against.
    - **Completeness.** We don't prove that every valid legal argument
      can be encoded.
    - **Instance resolution correctness.** The Agda sketch doesn't model
      GHC's typeclass resolution mechanism.

## Future Work

A deeper formalization would:

1. Define a denotational semantics for stratified defeasible logic
2. Prove that the `Judgment` GADT is sound with respect to that semantics
3. Model the layer resolution strategy and prove it implements the
   intended priority ordering
4. Extend to full dependent types, potentially encoding the statutory
   text itself as a type
