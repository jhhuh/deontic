# Deontic — Curry-Howard Isomorphism for Deontic Logic

A Haskell framework that formalizes legal codes as type-level programs, using GHC's typeclass instance resolution as a defeasibility resolver.

## The Idea

Legal reasoning is **defeasible** — a general rule ("contracts are valid") can be overridden by a more specific one ("contracts obtained by fraud are voidable"). Traditional Curry-Howard encodings break down here because proofs are supposed to be irrefutable.

This project resolves the tension by encoding **override layers as a type-level list** parameter on a typeclass. Each instance's context constraint (`=>`) chains to the layer below, and GHC's instance resolver walks the chain top-down. The result is a `Judgment` GADT that carries the full reasoning chain — a proof term you can inspect, render, and verify.

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

**Key properties:**
- **Soundness via types**: If it type-checks, the override chain is well-formed
- **법의 흠결 (lacuna)**: An act type with no `Resolvable` instance is a type error — gaps in the law are compile errors
- **Open**: Layers, facts, and act types are all extensible via type families — no modification to the core framework needed
- **Proof-as-sentence**: The `Judgment` GADT can be rendered as a Korean legal reasoning chain (판결문)

## Project Structure

```
deontic-core/                    -- Framework (jurisdiction-agnostic)
  Deontic.Core.Types             -- PersonId, ActId, ArticleRef, Facts type family
  Deontic.Core.Verdict           -- Valid | Void | Voidable, verdictMeet
  Deontic.Core.Layer             -- Layer tokens (Base, Proviso, SpecialRule), Resolvable
  Deontic.Core.Adjudicate        -- Adjudicate typeclass, Judgment GADT, query
  Deontic.Render                 -- Step extraction, Renderer typeclass

deontic-kr-civil/                -- Korean Civil Act (민법) encoding
  Deontic.Civil.Types            -- Act types + CivilFact ADT (type-safe facts)
  Deontic.Civil.Persons          -- §5 미성년자의 법률행위
  Deontic.Civil.Acts             -- §103-104, §107-110 법률행위
  Deontic.Civil.Agency           -- §114-132 대리
  Deontic.Civil.Possession       -- §197, §200 점유 추정 (rebuttable presumptions)
  Deontic.Civil.Render           -- KoreanRenderer (Judgment → 판결문)
```

## Articles Encoded

| Article | Act Type | Layers | What it encodes |
|---------|----------|--------|-----------------|
| §5 미성년자의 법률행위 | `MinorAct` | `'[Proviso, Base]` | Consent required; proviso for rights-only acts |
| §103 반사회질서 | `JuristicAct` | `'[SpecialRule, Proviso, Base]` | Contra bonos mores → Void |
| §104 불공정한 법률행위 | `JuristicAct` | (same stack) | Exploitative act → Void |
| §107 비진의 의사표시 | `JuristicAct` | (same stack) | Hidden intention: valid unless counterparty knew |
| §108 통정허위표시 | `ShamAct` | `'[Proviso, Base]` | Sham → Void; bona fide third party protected |
| §109 착오 | `MistakeAct` | `'[Proviso, Base]` | Mistake → Voidable; not if gross negligence |
| §110 사기·강박 | `FraudAct` | `'[Proviso, Base]` | Fraud/duress → Voidable; third-party fraud rules |
| §114 유권대리 | `AuthAgencyAct` | `'[Proviso, Base]` | Authorized agency → Valid; self-dealing → Voidable |
| §125-129 표현대리 | `UnauthAgencyAct` | `'[ApparentAuth, Ratification, Base]` | Apparent authority → Valid |
| §130 무권대리 | `UnauthAgencyAct` | (same stack) | Unauthorized → Pending; ratification → Valid |
| §197 점유의 태양 | `PossessionAct` | `'[Rebuttal, Presumption]` | Presumed good faith; rebutted by bad faith/violence/secrecy |
| §200 소유의사 추정 | `PossessionAct` | (same stack) | Presumed ownership intent; rebutted by contrary evidence |

## Example

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

The `Judgment` value carries the full reasoning chain. Render it:

```haskell
import Deontic.Render (Renderer(..))
import Deontic.Civil.Render (KoreanRenderer(..))

renderJudgment KoreanRenderer j
-- 판단: 본 법률행위는 유효하다.
--
-- 근거:
--   민법 제5조 제1항에 의하면,
--   "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다."
--
--   민법 제5조 제1항에 의하여 이를 번복하면,
--   "권리만을 얻거나 의무만을 면하는 법률행위는 그러하지 아니하다."
--
-- 따라서, 본 법률행위는 유효하다.
```

## Design Principles

**Open type families everywhere.** The core framework defines:
- `type family Resolvable act :: [Type]` — what layers apply to an act
- `type family Facts act :: Type` — what facts an act needs
- Layer tokens are just uninhabited types — define your own

**Polymorphic tails.** Each layer instance only knows "I sit on top of something":
```haskell
instance Adjudicate act rest => Adjudicate act (Proviso ': rest)
```
Layers are composable building blocks, not hardcoded to a specific stack.

**Independent defects, not a giant stack.** Different defect types (`ShamAct`, `MistakeAct`, `FraudAct`) are separate act types with their own stacks. Combine independent verdicts with `verdictMeet` (Void > Voidable > Valid).

**Rebuttable presumptions via layer defaults.** Legal presumptions ("A로 추정한다") map to a `Presumption` base layer (default Valid) with a `Rebuttal` override layer. The absence of rebuttal facts causes delegation → the presumption holds. No explicit negation needed.

## Prior Art

- **Catala** (INRIA) — DSL for legislative drafting; runtime interpretation, not Curry-Howard
- **SPINdle** (Governatori) — Defeasible logic engine; Prolog-style, no type-level guarantees
- **Pfenning-Davies** — Curry-Howard for modal logic; foundational but not deontic-specific

This project differs by using GHC's type system itself as the logic engine — defeasibility is resolved at the type level, and the proof term is a first-class value.

## Building

Requires Nix with flakes enabled:

```bash
nix develop -c cabal build all
nix develop -c cabal test all
```

## License

AGPL-3.0-or-later. See [LICENSE](LICENSE) for details.

For commercial licensing inquiries, please contact the author.
