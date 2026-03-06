# Curry-Howard Isomorphism

The Curry-Howard isomorphism (also called the "proofs-as-programs"
correspondence) is a deep connection between logic and computation.
It states that **logical proofs and typed programs are the same thing**,
viewed from different perspectives.

## The Core Correspondence

| Logic | Type Theory | Programming |
|-------|-------------|-------------|
| Proposition $A$ | Type `A` | Specification |
| Proof of $A$ | Term `t : A` | Program |
| Implication $A \to B$ | Function type `A → B` | Function |
| Conjunction $A \land B$ | Product type `(A, B)` | Pair / struct |
| Disjunction $A \lor B$ | Sum type `Either A B` | Tagged union |
| Truth $\top$ | Unit type `()` | Trivial value |
| Falsity $\bot$ | Empty type `Void` | Impossible / abort |
| Universal $\forall x. P(x)$ | Polymorphism `forall a. P a` | Generic function |
| Existential $\exists x. P(x)$ | Existential type | Module / abstract type |
| Modus ponens | Function application | Calling a function |
| Hypothesis | Variable | Assumption |

## A Simple Example

Consider the logical tautology $A \to A$ ("if $A$, then $A$"). Under
Curry-Howard, this becomes the identity function:

=== "Logic"
    ```
    Proof of A → A:
      Assume A.        (hypothesis)
      Then A.          (by assumption)
      Therefore A → A. (→-introduction)
    ```

=== "Haskell"
    ```haskell
    id :: a -> a
    id x = x
    ```

The proof *is* the program. The type *is* the proposition. If the program
type-checks, the proposition is proven.

## A More Interesting Example

The logical rule of *syllogism*: $(A \to B) \to (B \to C) \to (A \to C)$.

=== "Logic"
    ```
    Given: A → B and B → C
    Assume A.
    By A → B, we have B.
    By B → C, we have C.
    Therefore A → C.
    ```

=== "Haskell"
    ```haskell
    compose :: (a -> b) -> (b -> c) -> (a -> c)
    compose f g x = g (f x)
    ```

This is just function composition — `(.)` in Haskell.

## Curry-Howard for Richer Logics

The basic correspondence covers intuitionistic propositional logic.
Extensions add more expressiveness:

| Logic Extension | Type System Extension | Language Feature |
|----------------|----------------------|------------------|
| Classical logic | Continuations | `callCC` |
| Linear logic | Linear types | Ownership (Rust) |
| Modal logic S4 | Staged types $\Box A$ | Metaprogramming |
| Dependent types | $\Pi$-types, $\Sigma$-types | Agda, Coq, Idris |

### Dependent Types: The Full Correspondence

In dependently-typed languages like Agda and Coq, the correspondence is
**complete** — every constructive proof can be expressed as a program, and
vice versa. This enables:

```agda
-- A proof that addition is commutative
+-comm : ∀ (m n : ℕ) → m + n ≡ n + m
+-comm zero    n = sym (+-identityʳ n)
+-comm (suc m) n = trans (cong suc (+-comm m n)) (sym (+-suc n m))
```

The type `m + n ≡ n + m` is the proposition; the term is the proof;
and Agda's type-checker verifies it mechanically.

## The Problem with Legal Reasoning

Curry-Howard works beautifully for **irrefutable** reasoning. But legal
reasoning is **defeasible**:

```
§5①: "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다."
     (A minor needs guardian consent for juristic acts.)

     This implies: Minor + No Consent → Voidable
```

Under classical Curry-Howard, once we have a proof of `Voidable`, it
cannot be retracted. But:

```
§5① 단서: "그러나 권리만을 얻거나 의무만을 면하는 행위는 그러하지 아니하다."
           (But acts that merely acquire rights are exempt.)

           This implies: Minor + No Consent + MerelyAcquiresRight → Valid
```

The 단서 (proviso) **overrides** the 본문 (main rule). A proof of
`Voidable` from the main rule is **defeated** by the proviso. Classical
Curry-Howard has no mechanism for this.

## Our Resolution

We don't abandon Curry-Howard — we **extend** it. Instead of a single
proof, we produce a `Judgment` that carries the **full reasoning chain**,
including which layers were consulted and which overrode which:

```haskell
data Judgment (layers :: [Type]) where
  JBase     :: Verdict -> ArticleRef -> Text -> Judgment '[l]
  JOverride :: Judgment prev -> Verdict -> ArticleRef -> Text
            -> Judgment (l ': prev)
  JDelegate :: Judgment prev -> Judgment (l ': prev)
```

The `Judgment` GADT is the proof term. It satisfies a modified
Curry-Howard correspondence:

| Classical | Defeasible (Ours) |
|-----------|-------------------|
| Proposition | Act type + Layer stack |
| Proof | `Judgment layers` value |
| Modus ponens | `query` (typeclass resolution) |
| Irrefutable | Override chain (highest-priority layer wins) |
| Type-checking = verification | Compile-time layer stack completeness |

The key insight: **GHC's typeclass instance resolution is the proof search
engine**, and the type-level list of layers is the **priority structure**
that makes reasoning defeasible. See [Defeasible Reasoning](defeasibility.md)
for the full encoding strategy.
