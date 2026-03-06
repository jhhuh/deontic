# Framework Architecture

The `deontic-core` package provides the jurisdiction-agnostic framework.
It defines the core abstractions that all jurisdiction-specific packages
build on.

## Module Map

```
Deontic.Core.Types      — PersonId, ActId, ArticleRef, Facts type family
Deontic.Core.Verdict    — Verdict type + verdictMeet semilattice
Deontic.Core.Layer      — Layer tokens (Base, Proviso, SpecialRule) + Resolvable
Deontic.Core.Adjudicate — Adjudicate typeclass + Judgment GADT + query
Deontic.Render          — Step extraction + Renderer typeclass
```

## Design Principles

**Open type families everywhere.** The core framework defines three
extension points:

- `type family Resolvable act :: [Type]` — what layers apply to an act
- `type family Facts act :: Type` — what evidence an act requires
- Layer tokens are just uninhabited types — define your own

**Zero jurisdiction-specific code.** The core has no Korean, German, or
any other legal content. It provides the *structure* of defeasible
reasoning; jurisdictions provide the *substance*.

**Polymorphic tails.** Each layer instance only knows "I sit on top of
something." Layers are composable building blocks, not hardcoded to a
specific stack.

## Detailed Pages

- [Core Architecture](core.md) — types, classes, and how they fit together
- [Judgment GADT & Layers](judgment.md) — the proof term and override mechanism
- [Verdict Algebra](verdict.md) — the semilattice of legal outcomes
- [Facts Type Family](facts.md) — heterogeneous evidence structures
