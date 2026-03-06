# Deontic — Curry-Howard for Defeasible Deontic Logic

A Haskell framework that formalizes legal codes as type-level programs,
using GHC's typeclass instance resolution as a defeasibility resolver.

## The Problem

Legal reasoning is **defeasible** — a general rule ("contracts are valid")
can be overridden by a more specific one ("contracts obtained by fraud are
voidable"). Traditional Curry-Howard encodings break down here because proofs
are supposed to be irrefutable.

## The Insight

GHC's typeclass instance resolution **is** a defeasibility resolver.
Override layers are encoded as a type-level list parameter on a typeclass.
Each instance's context constraint chains to the layer below, and GHC's
instance resolver walks the chain top-down. The result is a `Judgment` GADT
that carries the full reasoning chain — a proof term you can inspect, render,
and verify.

```
                GHC instance resolution
                ═══════════════════════
                          ↓
  type instance Resolvable MinorAct = '[Proviso, Base]
                                         │       │
  ┌──────────────────────────────────────┘       │
  │  instance Adjudicate MinorAct rest           │
  │        => Adjudicate MinorAct (Proviso ': rest)
  │     -- §5① 단서: override if merely acquires right
  │                                               │
  └───────────────────────────────────────────────┘
     instance Adjudicate MinorAct '[Base]
     -- §5① 본문: base rule (consent required)
```

## Key Properties

- **Soundness via types** — if it type-checks, the override chain is well-formed
- **법의 흠결 (lacuna)** — an act type with no `Resolvable` instance is a type error; gaps in the law are compile errors
- **Open** — layers, facts, and act types are all extensible via type families
- **Proof-as-sentence** — the `Judgment` GADT can be rendered as a Korean legal reasoning chain (판결문)

## Quick Example

```haskell
import qualified Data.Set as Set
import Deontic.Core.Types (PersonId(..), ActId(..))
import Deontic.Core.Verdict (verdict, Verdict(..))
import Deontic.Core.Adjudicate (query)
import Deontic.Civil.Types (MinorAct(..), CivilFact(..))
import Deontic.Civil.Persons ()  -- brings instances into scope

-- A minor makes a contract without guardian consent
let j = query (MinorAct (PersonId "김철수") (ActId "매매계약"))
              (Set.fromList [IsMinor (PersonId "김철수")])
verdict j  -- => Voidable

-- But if the act merely acquires a right (§5① 단서)
let j = query (MinorAct (PersonId "김철수") (ActId "증여수령"))
              (Set.fromList [IsMinor (PersonId "김철수"), MerelyAcquiresRight])
verdict j  -- => Valid
```

## Project Structure

| Package | Description |
|---------|-------------|
| [`deontic-core`](framework/core.md) | Jurisdiction-agnostic framework: Judgment GADT, Verdict, Layers |
| [`deontic-kr-civil`](civil-act/index.md) | Korean Civil Act (민법) — 15 modules, 35+ articles, 166 tests |
| [`deontic-de-bgb`](bgb/index.md) | German BGB fragment — §104-§113 Geschäftsfähigkeit |
| [`agda-sketch`](verification/index.md) | Agda formal verification sketch |

## Building

Requires Nix with flakes enabled:

```bash
nix develop -c cabal build all
nix develop -c cabal test all
nix run .#mkdocs        # build documentation site
```

## Theoretical Background

New to modal logic or deontic logic? Start with the [Theory](theory/index.md) section,
which covers the logical foundations from modal logic through defeasible reasoning
and how they connect to computation via the Curry-Howard isomorphism.
