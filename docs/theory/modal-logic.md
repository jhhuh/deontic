# Modal Logic

Modal logic extends classical propositional and predicate logic with
**modalities** — operators that qualify the truth of propositions. Where
classical logic asks "is $\varphi$ true?", modal logic asks "is $\varphi$
*necessarily* true?" or "is $\varphi$ *possibly* true?"

## The Basic Operators

| Symbol | Name | Reading |
|--------|------|---------|
| $\Box \varphi$ | Necessity | "it is necessary that $\varphi$" |
| $\Diamond \varphi$ | Possibility | "it is possible that $\varphi$" |

These are duals: $\Diamond \varphi \equiv \neg\Box\neg\varphi$.
"It is possible that $\varphi$" means "it is not necessary that not-$\varphi$."

## Kripke Semantics

The standard semantics for modal logic uses **Kripke frames** (Saul Kripke, 1959).

!!! info "Kripke Frame"
    A Kripke frame is a pair $(W, R)$ where:

    - $W$ is a set of **possible worlds**
    - $R \subseteq W \times W$ is an **accessibility relation**

    A **Kripke model** adds a valuation $V : W \to \mathcal{P}(\text{Prop})$ that
    assigns which atomic propositions are true at each world.

**Truth at a world** $w$:

- $w \vDash \Box\varphi$ iff for all $v$ with $wRv$, $v \vDash \varphi$
  ("$\varphi$ is true in every accessible world")
- $w \vDash \Diamond\varphi$ iff there exists $v$ with $wRv$ and $v \vDash \varphi$
  ("$\varphi$ is true in some accessible world")

The accessibility relation $R$ determines the **strength** of the modality.
Different constraints on $R$ yield different modal logics:

| Constraint | Name | Logic |
|-----------|------|-------|
| None | — | K (basic) |
| Reflexive ($wRw$) | Every world accesses itself | T |
| Reflexive + Transitive | — | S4 |
| Equivalence relation | All worlds see each other | S5 |

## Modal Logic as Computation

Modal logic has deep connections to computer science:

| Modal concept | Computational counterpart |
|--------------|--------------------------|
| $\Box\varphi$ (necessity) | Pure computation (value available in all contexts) |
| $\Diamond\varphi$ (possibility) | Effectful computation (value available in some context) |
| Possible worlds | Execution states / environments |
| Accessibility | Reachability between states |

### The Curry-Howard Connection

Pfenning and Davies (2001) established a direct Curry-Howard correspondence
for the modal logic S4:

| Modal Logic S4 | Type Theory |
|---------------|-------------|
| $\Box A$ | $\square A$ (closed/pure term) |
| Necessitation rule | Lambda abstraction over contexts |
| $\Box$-elimination | Application in an empty context |
| Worlds | Stages / contexts |

This is the foundation for **staged computation** — metaprogramming where
$\Box A$ represents "a program that produces $A$" as opposed to "a value of
type $A$."

### Monads as Modalities

There is also a correspondence between modalities and monads:

- $\Diamond A$ corresponds to a monad $M\,A$ — "an $A$ that may require effects"
- The monadic `return : A → M A` corresponds to the T axiom $A \to \Diamond A$
- The monadic `join : M (M A) → M A` corresponds to transitivity of $\Diamond$

Moggi's (1991) computational lambda calculus, which underlies Haskell's `IO` monad,
is essentially a modal logic where $\Diamond$ captures computational effects.

## Why This Matters for Legal Reasoning

Legal modalities don't map directly onto alethic necessity/possibility.
When a statute says "a minor *shall* obtain consent," the "shall" is not
$\Box$ (necessity) but $O$ (obligation) — a different modality that lives
in **deontic logic**, which we cover [next](deontic-logic.md).

However, the Kripke semantics machinery transfers: deontic modalities also
have possible-worlds semantics, and the Curry-Howard connections extend to
give us a computational interpretation of normative reasoning.
