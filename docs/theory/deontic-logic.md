# Deontic Logic

Deontic logic is the logic of **norms** — obligation, permission, and prohibition.
It applies the framework of modal logic to normative reasoning, replacing
necessity/possibility with ought/may.

## The Deontic Operators

| Symbol | Name | Reading |
|--------|------|---------|
| $O\varphi$ | Obligation | "it is obligatory that $\varphi$" |
| $P\varphi$ | Permission | "it is permitted that $\varphi$" |
| $F\varphi$ | Prohibition | "it is forbidden that $\varphi$" |

These are interdefinable:

- $P\varphi \equiv \neg O\neg\varphi$ — "permitted" = "not obliged not to"
- $F\varphi \equiv O\neg\varphi$ — "forbidden" = "obliged not to"
- $F\varphi \equiv \neg P\varphi$ — "forbidden" = "not permitted"

## Standard Deontic Logic (SDL)

Von Wright (1951) introduced Standard Deontic Logic by reinterpreting
the Kripke semantics of modal logic:

| Alethic ($\Box$/$\Diamond$) | Deontic ($O$/$P$) |
|------------------------------|---------------------|
| Possible worlds | **Deontically ideal worlds** |
| Accessibility relation $R$ | "ideality" — $wRv$ means $v$ is a world where all norms of $w$ are satisfied |
| $\Box\varphi$: true in all accessible worlds | $O\varphi$: true in all ideal worlds |
| $\Diamond\varphi$: true in some accessible world | $P\varphi$: true in some ideal world |

!!! info "SDL Axioms"
    SDL is a normal modal logic (system KD):

    - **K**: $O(\varphi \to \psi) \to (O\varphi \to O\psi)$ — obligation distributes over implication
    - **D**: $O\varphi \to P\varphi$ — if obligatory, then permitted (no conflicts)
    - **Necessitation**: if $\vdash \varphi$ then $\vdash O\varphi$ — tautologies are obligatory

## Problems with SDL

SDL has well-known limitations that make it inadequate for real legal reasoning:

### Contrary-to-Duty Paradoxes

The **Chisholm paradox** (1963):

1. It ought to be that Jones helps his neighbors. ($Oa$)
2. It ought to be that if Jones helps, he tells them. ($O(a \to b)$)
3. If Jones doesn't help, he ought not to tell them. ($\neg a \to O\neg b$)
4. Jones doesn't help. ($\neg a$)

In SDL, (1) and (4) yield a contradiction via the D axiom. Real legal
systems handle this routinely — there are primary duties, and separate
duties that apply when primary duties are violated.

### The Jørgensen Dilemma

Norms are not truth-apt — "you shall not steal" is neither true nor false.
But logical inference requires truth values. How can we have a logic of
norms?

Responses include:

- **Norm propositions**: reason about *descriptions* of norms ("it is the case that stealing is prohibited")
- **Pragmatic approach**: treat norms as having a truth-like status for purposes of reasoning
- **Our approach**: encode norms as *types*, sidestepping truth entirely via Curry-Howard

### Defeasibility

The most critical limitation: SDL has no notion of **exceptions** or
**overrides**. In law:

- "Contracts are binding" (general rule)
- "But contracts by minors without consent are voidable" (exception)
- "Except when the minor merely acquires a right" (exception to the exception)

SDL cannot represent this layered structure. This is where
**defeasible deontic logic** comes in.

## Defeasible Deontic Logic

Several frameworks extend deontic logic with defeasibility:

### Governatori's Defeasible Logic

Governatori et al. (2005) define a defeasible logic with three rule types:

- **Strict rules**: $A \to B$ (no exceptions)
- **Defeasible rules**: $A \Rightarrow B$ (can be overridden)
- **Defeaters**: $A \leadsto \neg B$ (blocks a conclusion without supporting the opposite)

Rules have a **superiority relation** $>$ that determines which rule prevails
in conflicts: if $r_1 > r_2$ and they conflict, $r_1$ wins.

### Horty's Reason-Based Approach

Horty (2012) models norms as **default reasons** that support conclusions
unless outweighed by stronger reasons. This yields a priority-based
framework close to how lawyers actually reason.

### Prakken & Sartor's Argumentation

Prakken and Sartor (1997) use **argumentation theory**: arguments for
and against a conclusion are constructed, and defeat relations determine
which arguments survive. An argument is **justified** if it is not
defeated by any justified counter-argument.

## Computational Deontic Logic

The connection between deontic logic and computation runs deeper than
analogy:

| Deontic Concept | Computational Counterpart |
|----------------|--------------------------|
| Obligation $O\varphi$ | Required postcondition / contract |
| Permission $P\varphi$ | Capability / authorization |
| Prohibition $F\varphi$ | Access control / invariant |
| Contrary-to-duty | Exception handling |
| Defeasibility | Method override / priority dispatch |

### Deontic Logic in Programming

- **Design by Contract** (Meyer, 1992): preconditions, postconditions,
  and invariants are deontic constraints on program behavior
- **Access control**: RBAC/ABAC policies are essentially deontic rules
  — "role R is permitted to access resource X"
- **Smart contracts**: blockchain contracts encode obligations and
  permissions as executable code

### Our Approach: Typeclass Resolution as Defeasibility

This project takes a novel approach: we use GHC's **typeclass instance
resolution** as the defeasibility mechanism. The layered override
structure of defeasible deontic logic maps directly onto type-level
lists of instances. See [Defeasible Reasoning](defeasibility.md) for
the detailed encoding.
