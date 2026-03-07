## Analysis: Current Limitations and Extensibility

### Current State

Across 6 Supreme Court cases, the framework accurately encodes **statutory
text** (조문) but does not yet reflect **case-law doctrines** (판례법리)
— judge-made exceptions established through precedent.

| Case | Match | Missing doctrine |
|:-----|:------|:-----------------|
| 2005다71659 | ⚠️ partial | Reasoning chain for §6 implied consent (처분허락) |
| 94다12074 | ⚠️ partial | Conditional judgment pending fact-finding (선의 여부) |
| 2013다49794 | ⚠️ partial | Counterparty exploitation defeats gross-negligence bar (§109 판례법리) |
| 2019다280375 | ❌ mismatch | Registration chain validity analysis (등기법 layer) |
| 98다60828 | ❌ mismatch | Agent identifiable with counterparty ≠ third party (§110②) |
| 91다32190 | ❌ mismatch | Factual-act delegation ≠ basic agency authority (§126 prerequisite) |

### What This Means

The mismatches are not **design limitations** — they are **encoding coverage
gaps**. The framework's core engine already supports the exact mechanism
needed to close them: **stratified defeasible reasoning**.

Each legal rule can override a lower layer's verdict, and the entire
override chain is preserved as a type-level proof term:

```haskell
-- Base rule application
JBase     :: Verdict → ArticleRef → Text → Judgment '[l]
-- Higher layer overrides lower layer's verdict
JOverride :: Judgment prev → Verdict → ArticleRef → Text → Judgment (l ': prev)
-- Higher layer delegates (does not override)
JDelegate :: Judgment prev → Judgment (l ': prev)
```

To close the gaps identified above:

**98다60828** — Add an `AgentIdentifiableWithCounterparty` fact. When present,
a new layer overrides §110②'s third-party fraud restriction. The existing
§110 rules remain untouched.

**2013다49794** — Add a `CounterpartyExploitedMistake` fact. When present,
a new layer overrides §109's gross-negligence bar. The existing §109 rule
remains untouched.

**91다32190** — Add a `DelegatedFactualActOnly` fact. When present,
it blocks §126 apparent authority from applying as a precondition. The
existing §126 rule remains untouched.

Each extension adds **new fact types and new layers** without modifying
existing rules. This is the defeasible reasoning engine working as designed.

### The Verification Pipeline as a Development Tool

This comparison pipeline mechanically identifies where the framework
needs to grow:

1. Encode a court case as facts
2. Generate framework output (purely mechanical)
3. A zero-context LLM compares output against the actual judgment
4. Each mismatch **is** the next doctrine to encode

Mismatch ≠ failure. Mismatch = next work item.
