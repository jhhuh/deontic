# Second-Order Defeasibility: Beyond the Logic

This page documents a key finding of the Deontic project: certain legal
concepts require **second-order** reasoning — rules that operate on the
*outputs* of other legal evaluations — which is absent from standard
defeasible deontic logic. We identify this gap, show how our framework
fills it, and analyze the implications.

## The Gap in the Literature

### What Defeasible Deontic Logic Provides

Standard defeasible logic (Nute 1994, Governatori et al. 2005) provides a
first-order rule system:

$$r: A_1, A_2, \ldots, A_n \Rightarrow B$$

Rules map **facts to conclusions**. When rules conflict, a **superiority
relation** $r_1 > r_2$ determines which prevails. The key operations are:

- **Derivation**: given facts, derive a conclusion
- **Defeat**: given conflicting rules, determine the winner
- **Propagation**: chain conclusions forward as new facts

Dung's (1995) argumentation frameworks add a layer: arguments attack other
arguments. But the attack relation is **declared externally** by the
framework designer, not **computed internally** by an argument inspecting
another argument's conclusion.

Prakken and Sartor's (1997) argumentation handles **meta-rules** — rules
about rules (lex specialis, lex posterior). But these meta-rules are
typically **flattened** into the same priority ordering as object-level
rules, losing the structural distinction between evaluating a legal act
and evaluating the *status* of that evaluation.

### What Legal Reasoning Requires

Two patterns in actual statute law go beyond this:

**1. Meta-rules on evaluation outputs.** Korean Civil Act §141 says: "a
cancelled voidable act is deemed void from the beginning." This rule does
not operate on facts about the world — it operates on the *legal status
of an act*, which is itself the output of a prior legal evaluation. The
input is a verdict, not a fact.

**2. Counterfactual re-evaluation.** §150 says: if a party prevents a
condition's fulfillment in bad faith, the other party may *deem* the
condition fulfilled. This requires re-evaluating the entire act *as if*
the condition were fulfilled — a counterfactual query over the same rule
system with modified facts.

Neither pattern is expressible in standard defeasible logic, where all
rules operate at the same level: facts in, conclusions out.

### Related Theoretical Concepts

These patterns correspond to well-studied concepts in jurisprudence that
have not been formalized in the logic:

| Legal concept | Description | Logic status |
|---|---|---|
| **형성권 (Gestaltungsrecht)** | Power to unilaterally change legal relations (e.g., 취소권, 해제권) | Recognized by Hohfeld (1913) as second-order; no defeasible logic encoding |
| **법률요건의 중첩** | Legal requirements that reference other legal conclusions | Discussed by Larenz; typically handled by manual chaining |
| **법적 의제 (legal fiction)** | "Deemed" states — treat $X$ as if $Y$ were true | Closest to counterfactual conditionals (Lewis 1973); not in deontic logic |
| **Meta-rules** | Rules about how rules apply (lex specialis, lex posterior) | Sartor discusses; typically flattened into priority orderings |

The gap is clear: jurisprudence recognizes these as structurally distinct
from first-order rules, but the standard logics collapse them into the
same mechanism.

## Our Solution

Our framework fills this gap by exploiting a property of its host language:
**Haskell is a general-purpose programming language**, not just a logic. The
type system handles first-order defeasibility (layer stacks, instance
resolution), while ordinary Haskell computation handles second-order
features (passing values, calling functions recursively).

This gives us two clean patterns.

### Pattern A: Verdict-as-Input (Wrapper)

A **wrapper act type** takes a prior `Verdict` as a field in its input
record. The framework evaluates the wrapper as a normal act type, but its
base layer inspects the prior verdict instead of (or in addition to)
world-facts.

```haskell
data CancellableAct = CancellableAct
  { caActId        :: ActId
  , caPriorVerdict :: Verdict   -- output of a previous query
  }
```

The evaluation pipeline becomes:

```
         First-order evaluation          Second-order evaluation
         ════════════════════            ═══════════════════════
  facts₁ ──→ query act₁ facts₁ ──→ v₁ ──→ CancellableAct { caPriorVerdict = v₁ }
                                           ──→ query cancellableAct facts₂ ──→ v₂
```

This is a **manual composition** — the caller chains the two evaluations.
The framework itself remains first-order; the second-order structure lives
in the call site.

**Why not automate this?** We could add a framework-level concept of
"evaluation phases" or "meta-layers." But the manual approach has
advantages:

1. **Explicit.** The caller sees both evaluations and controls the data flow.
2. **Flexible.** The prior verdict can come from any act type — `CancellableAct`
   is generic over what it wraps.
3. **Simple.** No new framework concepts needed. The `Adjudicate` typeclass,
   `Judgment` GADT, and `query` function are unchanged.

#### Legal fidelity

In Korean civil law, cancellation (취소) and ratification (추인) are
**separate legal questions** from the validity of the underlying act.
A lawyer first determines "is this act voidable?" and then separately
asks "was the voidable act cancelled or ratified?" The two-step evaluation
mirrors this reasoning structure.

Practitioners would find it unnatural to combine these into a single
evaluation — they are taught as distinct doctrines (§140-§145 form a
self-contained section in the 민법).

### Pattern B: Recursive Query (Counterfactual Re-evaluation)

An `Adjudicate` instance calls `query` **recursively** with modified facts,
obtaining a counterfactual verdict that it uses as its override value.

```haskell
-- §150: 반신의행위
instance Adjudicate ConditionalAct rest
      => Adjudicate ConditionalAct (BadFaithCondition ': rest) where
  adjudicate act facts = case condBadFaith facts of
    Just BadFaithPrevention ->
      let deemedFacts  = facts { condState    = CondFulfilled
                               , condBadFaith = Nothing }
          deemedResult = query act deemedFacts
      in JOverride (adjudicate @_ @rest act facts)
                   (verdict deemedResult)
                   (ArticleRef "민법" 150 (Just 1))
                   "..."
```

The evaluation pipeline:

```
                    ┌──────── Recursive query ────────┐
                    │                                  │
  facts ──→ BadFaithCondition layer                    │
               │                                       │
               ├─ condBadFaith = Just Prevention       │
               │    deemedFacts = facts[Fulfilled, ∅]  │
               │    query act deemedFacts ─────────────┘
               │         │
               │         └──→ IllegalCondition (delegates)
               │               └──→ Base (truth table lookup)
               │                      └──→ verdict ──→ used as override
               │
               └─ condBadFaith = Nothing
                    JDelegate (pass through)
```

Unlike Pattern A, this is **not** a manual composition at the call site.
The recursion happens *inside* the framework's resolution machinery. An
`Adjudicate` instance — which is supposed to be a "rule" in the
defeasible logic — is calling back into the `query` entry point, making
it a second-order rule.

#### Legal fidelity

§150 uses the language "성취한 **것으로** 주장할 수 있다" — "may assert
**as if** [the condition were] fulfilled." The statute literally instructs
a counterfactual re-evaluation. The recursive `query` mirrors this
precisely: evaluate the same act under the assumption that the condition
was fulfilled, and use the resulting verdict.

A first-order encoding (inlining the truth table) would produce the same
verdicts for the current implementation. But it would not capture the
legal semantics — §150 does not say "if suspensive, then Valid; if
resolutive, then Void." It says "evaluate as if fulfilled." The difference
matters if the lower layers change (e.g., a future judicial interpretation
adds a condition to the base rule).

## Termination Analysis

The recursive query raises an obvious concern: can it diverge?

### Current Implementation

**Depth bound: exactly 1.** The recursive call sets `condBadFaith = Nothing`.
On re-entry:

1. `BadFaithCondition` layer checks `condBadFaith facts` → `Nothing` → `JDelegate`
2. `IllegalCondition` layer checks `condState facts` → `CondFulfilled` → `JDelegate`
3. `Base` layer looks up `(condType, CondFulfilled)` in truth table → `JBase`

No further recursion occurs. The call graph is:

```
query act facts                          -- depth 0
  └─ BadFaithCondition: condBadFaith = Just ...
       └─ query act deemedFacts          -- depth 1
            └─ BadFaithCondition: condBadFaith = Nothing
                 └─ JDelegate            -- no recursion
                      └─ ... → JBase     -- terminates
```

### Safety Properties

| Property | Status | Mechanism |
|---|---|---|
| Termination | Guaranteed | `condBadFaith = Nothing` removes trigger |
| Purity | Guaranteed | `query` is pure; no shared mutable state |
| Correctness | Verified | 13 tests cover all condition type × bad faith combinations |
| Composability | Limited | See below |

### Limitations and Risks

**Convention, not invariant.** The termination guarantee depends on the
programmer setting `condBadFaith = Nothing` in the modified facts. This is
a coding convention, not a type-level guarantee. GHC cannot verify that
the recursive call will terminate.

Possible mitigations (not currently implemented, as only one recursive
site exists):

1. **Newtype wrapper**: `newtype DeemedFacts = DeemedFacts ConditionalFacts`
   that cannot trigger `BadFaithCondition`. Requires a separate
   `Adjudicate` instance chain.
2. **Depth counter**: Add `condDepth :: Int` to `ConditionalFacts`, checked
   at entry. Simple but ad-hoc.
3. **Separate act type**: `DeemedConditionalAct` with its own layer stack
   that excludes `BadFaithCondition`. Most type-safe but adds boilerplate.

**Non-composable.** If two act types both used recursive `query` and could
appear in each other's evaluation chains, mutual recursion could arise.
Currently safe because `ConditionalAct` is the only recursive-query user
and it only queries itself. Adding a second recursive-query act type would
require careful analysis.

## Theoretical Significance

### What This Means for Defeasible Deontic Logic

Standard defeasible deontic logic operates at a single level:

$$\text{Facts} \xrightarrow{\text{rules + priorities}} \text{Conclusions}$$

Our second-order patterns reveal that statute law requires (at least) two
additional levels:

$$\text{Facts} \xrightarrow{\text{first-order rules}} \text{Verdict}_1 \xrightarrow{\text{meta-rules}} \text{Verdict}_2$$

$$\text{Facts} \xrightarrow{\text{rules}} \text{Verdict} \quad \text{but also} \quad \text{Facts}' \xrightarrow{\text{same rules}} \text{Verdict}' \xrightarrow{\text{used by}} \text{Verdict}$$

These correspond to distinct theoretical needs:

- **Meta-rules** require a notion of *evaluation output as input* —
  treating verdicts as first-class values that can be passed between
  evaluations. This is natural in a functional programming setting but
  absent in rule-based logics where conclusions are propositions in a
  fixed language.

- **Counterfactual re-evaluation** requires a notion of *self-reference*
  — a rule system that can invoke itself under modified assumptions. This
  is related to fixed-point semantics in logic programming, but the
  standard defeasible logic literature does not discuss it in the context
  of legal fictions.

### Relationship to Hohfeld's Framework

Wesley Hohfeld (1913) classified legal relations into two tiers:

| First-order | Second-order |
|---|---|
| Right / Duty | Power / Liability |
| Privilege / No-right | Immunity / Disability |

A **right** is a first-order relation: "A has a right that B shall pay."
A **power** is second-order: "A has the power to change A's legal
relations" — e.g., the power to cancel (취소권), which changes an act's
status from Voidable to Void.

Our wrapper pattern directly encodes Hohfeldian powers:

```
  query act facts → Voidable              -- first-order: right/duty
  query (CancellableAct v₁ ...) facts₂    -- second-order: power/liability
        → Void
```

This suggests that a complete formalization of Hohfeld's framework
*requires* second-order features in the logic — which may explain why
no existing defeasible deontic logic has fully captured it.

### Relationship to Catala

Catala (INRIA), the closest practical system for statute formalization,
handles both patterns through its general-purpose runtime:

- Meta-rules: Catala functions can take other evaluation results as
  arguments (wrapper pattern equivalent)
- Counterfactual: Catala functions can call other functions with modified
  inputs (recursive query equivalent)

But Catala has no type-level guarantees about defeasibility — its
"exceptions" mechanism is a runtime priority system. Our contribution is
showing that second-order features can coexist with type-level
defeasibility checking: the first-order structure is type-checked (layer
stacks, instance resolution), while the second-order structure uses
value-level computation within those type-checked instances.

## Summary

| Aspect | Standard Defeasible Logic | Our Framework |
|---|---|---|
| Rule input | Facts (world state) | Facts **or prior Verdict** |
| Rule output | Conclusion (proposition) | Verdict (first-class value) |
| Rule interaction | Priority ordering | Priority ordering **+ value passing** |
| Self-reference | Not supported | Recursive `query` with modified facts |
| Meta-rules | Flattened into priorities | Structurally distinct (wrapper pattern) |
| Hohfeldian powers | Not expressible | Naturally encoded via verdict-as-input |
| Counterfactual | Not supported | Recursive query with fact modification |
| Termination | Guaranteed by acyclicity | Guaranteed by convention (depth 1) |
| Type safety | N/A (no types) | First-order: type-checked; second-order: value-level |

The standard logics were designed for **first-order normative reasoning**
— determining what is obligatory, permitted, or forbidden given a set of
facts. Statute law also requires reasoning about **the status of prior
legal evaluations** (meta-rules) and **counterfactual re-evaluation under
modified assumptions** (legal fictions). Our framework handles both by
situating a type-level defeasibility resolver inside a general-purpose
functional language, using the language's native features (values,
functions, recursion) for the second-order parts.

This is not a limitation of the framework — it is an observation about
the *structure of law itself*. Legal systems have first-order rules
(validity, obligation, prohibition) and second-order rules (cancellation,
ratification, deemed states) that operate on the outputs of first-order
evaluation. Any formalization that aims for comprehensive statute coverage
will need to address this distinction, whether through second-order
features in the logic or, as we do, through the computational substrate.
