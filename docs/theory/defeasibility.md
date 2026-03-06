# Defeasible Reasoning: Our Encoding Strategy

This section explains how we bridge the gap between Curry-Howard's
irrefutable proofs and law's defeasible reasoning, using GHC's typeclass
instance resolution as the mechanism.

## The Core Idea

**Typeclass instance resolution is a defeasibility resolver.**

When GHC resolves `Adjudicate MinorAct '[Proviso, Base]`, it:

1. Looks up the instance for `(Proviso ': rest)` — the highest-priority layer
2. That instance's context requires `Adjudicate MinorAct rest` — triggering resolution of the next layer
3. At the bottom, `Adjudicate MinorAct '[Base]` — the base rule, no further delegation

This is exactly the operational semantics of **stratified defeasible logic**:

```
    ┌─────────────────────────────────────────┐
    │ Layer: Proviso (§5① 단서)               │
    │                                         │
    │ if MerelyAcquiresRight ∈ facts          │
    │   → JOverride prev Valid ...  (override)│
    │ else                                    │
    │   → JDelegate prev           (delegate) │
    └────────────────────┬────────────────────┘
                         │ calls adjudicate @rest
    ┌────────────────────▼────────────────────┐
    │ Layer: Base (§5① 본문)                   │
    │                                         │
    │ if HasConsent ∈ facts                   │
    │   → JBase Valid ...                     │
    │ else                                    │
    │   → JBase Voidable ...                  │
    └─────────────────────────────────────────┘
```

## The Encoding in Detail

### Layer Tokens

Layers are uninhabited types that serve as type-level tags:

```haskell
data Base          -- 원칙 (general rule)
data Proviso       -- 단서 (proviso/exception)
data SpecialRule   -- 특칙 (lex specialis)
```

Jurisdictions define their own:

```haskell
data Ratification    -- 추인 (§130, §132)
data ApparentAuth    -- 표현대리 (§125-129)
data Presumption     -- 추정 (default rule)
data Rebuttal        -- 반증 (rebuttal)
```

### The Resolvable Type Family

Each act type declares its layer stack:

```haskell
type family Resolvable act :: [Type]

type instance Resolvable MinorAct       = '[Proviso, Base]
type instance Resolvable UnauthAgencyAct = '[ApparentAuth, Ratification, Base]
type instance Resolvable TortAct        = '[ContributoryNeg, Base]
```

The list is ordered by priority: leftmost = highest priority.

### The Adjudicate Typeclass

```haskell
class Adjudicate act (layers :: [Type]) where
  adjudicate :: act -> Facts act -> Judgment layers
```

Two kinds of instances:

**Base instance** — the bottom of the stack, no further delegation:

```haskell
instance Adjudicate MinorAct '[Base] where
  adjudicate act facts
    | HasConsent ... `Set.member` facts = JBase Valid ...
    | otherwise                        = JBase Voidable ...
```

**Override instance** — delegates to the layer below, optionally overrides:

```haskell
instance Adjudicate MinorAct rest
      => Adjudicate MinorAct (Proviso ': rest) where
  adjudicate act facts
    | MerelyAcquiresRight `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts) Valid ...
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
```

### The Judgment GADT

The proof term:

```haskell
data Judgment (layers :: [Type]) where
  JBase     :: Verdict -> ArticleRef -> Text -> Judgment '[l]
  JOverride :: Judgment prev -> Verdict -> ArticleRef -> Text
            -> Judgment (l ': prev)
  JDelegate :: Judgment prev -> Judgment (l ': prev)
```

- **`JBase`** — base rule applied directly
- **`JOverride`** — this layer overrode the layer below
- **`JDelegate`** — this layer had no opinion, passed through

The `layers` type parameter tracks the exact layer stack, ensuring at
compile time that the judgment corresponds to the correct resolution
strategy.

## Soundness Argument

!!! note "What We Prove"
    If `query act facts` type-checks, the resulting `Judgment` is a
    well-formed proof under the applicable rules.

**Why:**

1. **Totality of the layer stack.** `Resolvable act` maps to a concrete
   type-level list. Each element must have a corresponding `Adjudicate`
   instance, or the program doesn't compile.

2. **Structural induction.** Each override instance requires the rest of
   the stack via its context constraint. GHC verifies this at compile time.

3. **No instance overlap.** For a given `(act, layers)` pair, at most one
   instance matches. Resolution is deterministic.

4. **Verdict extraction is total.** `verdict` pattern-matches on all three
   GADT constructors. This is verified by Agda in our
   [formal sketch](../verification/index.md).

## Comparison with Other Approaches

| System | Defeasibility Mechanism | Type Safety | Proof Terms |
|--------|------------------------|-------------|-------------|
| **Catala** (INRIA) | Runtime priorities | None | No |
| **SPINdle** (Governatori) | Prolog-style resolution | None | Trace only |
| **Pfenning-Davies** | None (modal, not defeasible) | Full | Yes |
| **This work** | **GHC instance resolution** | **Type-level** | **Judgment GADT** |

The unique contribution is using an existing industrial-strength type system
as both the logic engine and the soundness checker, producing first-class
proof terms that can be rendered as natural-language legal reasoning.

## Limitations

This is **not** a full formal verification:

- We don't have a formal semantics for the deontic logic fragment we encode
- We don't prove that the encoding is *faithful* to a particular semantics
- The Agda sketch proves structural properties (totality, algebra) but not
  faithfulness

What we do have is a **structural guarantee**: every judgment has consulted
every applicable layer in the correct order, and the reasoning chain is
preserved in the proof term. This is stronger than any runtime system but
weaker than a full formal verification.
