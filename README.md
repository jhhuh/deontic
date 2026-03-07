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

agda-sketch/                     -- Formal verification sketch (Agda)
  Deontic.agda                   -- Totality proof, verdict algebra proofs

deontic-de-bgb/                  -- German Civil Code (BGB) fragment
  Deontic.BGB.Types              -- CapacityAct, BGBFact
  Deontic.BGB.Capacity           -- §104-§113 Geschäftsfähigkeit

deontic-kr-civil/                -- Korean Civil Act (민법) encoding
  Deontic.Civil.Types            -- Act types + CivilFact ADT (type-safe facts)
  Deontic.Civil.Persons          -- §5 미성년자의 법률행위
  Deontic.Civil.Acts             -- §103-104, §107-110 법률행위
  Deontic.Civil.Agency           -- §114-132 대리
  Deontic.Civil.CoOwnership      -- §264 공유물의 처분 (universal quantification)
  Deontic.Civil.Possession       -- §197, §200 점유 추정 (rebuttable presumptions)
  Deontic.Civil.Prescription     -- §162, §168, §174 소멸시효 (calendar year, §157)
  Deontic.Civil.Tort             -- §750, §396 불법행위 (multi-element + contributory neg)
  Deontic.Civil.Rescission       -- §146 취소의 제척기간 (3년/10년, calendar year)
  Deontic.Civil.PropertyTransfer -- §186-188 물권변동 (formality + lex specialis)
  Deontic.Civil.AcquisitivePrescription -- §245 취득시효 (20년/10년, calendar year)
  Deontic.Civil.DefaultObligation -- §387-390 채무불이행 (breach + creditor defense)
  Deontic.Civil.SaleWarranty     -- §580-582 하자담보책임 (defect + buyer knowledge)
  Deontic.Civil.Lease            -- §618-640 임대차 (obligation + implicit renewal)
  Deontic.Civil.AgencyRemedies   -- §134-135 대리 철회·책임 (counterparty knowledge)
  Deontic.Civil.Invalidity       -- §137-139 일부무효·전환·추인 (meta-rules on void acts)
  Deontic.Civil.Cancellation     -- §141-145 취소·추인 (wrapper pattern on prior verdict)
  Deontic.Civil.ConditionalAct   -- §147-152 조건부 법률행위 (recursive query for §150)
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
| §162 소멸시효 | `PrescriptionAct` | `'[Interruption, Expiration]` | Claim expires after statutory period; interruption resets clock |
| §174 시효중단 효력 | `PrescriptionAct` | (same stack) | Interrupted prescription restarts from interruption point |
| §264 공유물의 처분 | `CoOwnershipAct` | `'[Base]` | Universal quantification: all co-owners must consent |
| §750 불법행위 | `TortAct` | `'[ContributoryNeg, Base]` | All 4 elements required; contributory negligence reduces |
| §396 과실상계 | `TortAct` | (same stack) | Victim negligence reduces liability (Void → Voidable) |
| §146 취소의 제척기간 | `RescissionAct` | `'[Base]` | 3-year/10-year exclusion period (calendar year, §157) |
| §186 부동산물권변동 | `PropertyTransferAct` | `'[FormException, Base]` | Registration required for real property |
| §187 등기불요 물권취득 | `PropertyTransferAct` | (same stack) | Inheritance/court order bypass registration |
| §188 동산물권양도 | `PropertyTransferAct` | (same stack) | Delivery required for movables |
| §245① 취득시효 | `AcqPrescriptionAct` | `'[ShortPrescription, Base]` | 20-year acquisitive prescription (calendar year) |
| §245② 단기취득시효 | `AcqPrescriptionAct` | (same stack) | 10-year if good faith + no negligence |
| §387-389 채무불이행 | `DefaultAct` | `'[CreditorDefense, Base]` | Non-performance + debtor fault → liability |
| §390 채권자과실 | `DefaultAct` | (same stack) | Creditor fault reduces liability (Void → Voidable) |
| §580 하자담보 | `WarrantyAct` | `'[BuyerKnowledge, Base]` | Defect → liability; significant defect → rescission |
| §580② 매수인 악의 | `WarrantyAct` | (same stack) | Buyer knew of defect → no warranty |
| §582 통지기간 | `WarrantyAct` | (same stack) | 6-month notification requirement |
| §618 임대차 | `LeaseAct` | `'[RenewalRight, Base]` | Lease validity and expiration |
| §639 묵시적 갱신 | `LeaseAct` | (same stack) | Implicit renewal: continued use + no objection |
| §640 차임연체 해지 | `LeaseAct` | (same stack) | 2-period rent arrears → termination |
| §134 상대방의 철회권 | `AgencyWithdrawalAct` | `'[CounterpartyKnowledge, Base]` | Counterparty may withdraw; not if knew of no authority |
| §135 무권대리인의 책임 | `AgentLiabilityAct` | `'[Proviso, Base]` | Agent liable; not if counterparty knew or agent limited-capacity |
| §137 일부무효 | `PartialInvalidityAct` | `'[Conversion, HypotheticalIntent, Base]` | Part void → whole void; hypothetical intent saves |
| §138 무효행위의 전환 | `PartialInvalidityAct` | (same stack) | Void act converts to valid if meets other act's requirements |
| §139 무효행위의 추인 | `PartialInvalidityAct` | (same stack) | Ratification with knowledge of defect → Valid |
| §141 취소의 효과 | `CancellableAct` | `'[ConstructiveRatification, GeneralRatification, Base]` | Wrapper: takes prior Verdict; cancelled Voidable → Void |
| §143-144 취소할 수 있는 행위의 추인 | `CancellableAct` | (same stack) | Ratification after cause ceases → Valid |
| §145 법정추인 | `CancellableAct` | (same stack) | Constructive ratification events → Valid |
| §147 조건부 법률행위 | `ConditionalAct` | `'[BadFaithCondition, IllegalCondition, Base]` | Suspensive/resolutive condition effects |
| §150 반신의행위 | `ConditionalAct` | (same stack) | Bad faith prevention → deemed fulfilled (recursive query) |
| §151 불법조건 | `ConditionalAct` | (same stack) | Illegal condition → Void; impossible condition truth table |
| §152 기한 | `ConditionalAct` | (same stack) | Start/end date effects on act validity |
| **BGB (German)** | | | |
| §104 Geschäftsunfähigkeit | `CapacityAct` | `'[SpecialRule, Proviso, Base]` | Under 7 or permanently incapable → Void |
| §106 beschränkte Geschäftsfähigkeit | `CapacityAct` | (same stack) | Minor without consent → Voidable |
| §107 rechtlicher Vorteil | `CapacityAct` | (same stack) | Purely beneficial → Valid (proviso) |
| §110 Taschengeld | `CapacityAct` | (same stack) | Pocket money → Valid (special rule) |

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

**Heterogeneous fact types.** The `Facts` type family lets each act type define its own fact structure. `MinorAct` uses `Set CivilFact` (boolean facts), while `PrescriptionAct` uses `PrescriptionFacts` (a record with `Day` fields for temporal reasoning). The core framework doesn't care — it just threads `Facts act` through.

**Calendar year computation (§157).** All temporal modules use `Data.Time.Day` with `addGregorianYearsClip` for proper calendar year arithmetic per §157 ("기간을 연으로 정한 때에는 역에 의하여 계산한다"). This correctly handles leap years — `2020-02-29 + 1년 = 2021-02-28`.

**Second-order patterns.** Some legal rules operate not on facts but on the *output of other legal evaluations*. Two second-order patterns emerge:

- **Wrapper pattern** (`CancellableAct`): Takes a prior `Verdict` as an input field. The cancellation/ratification meta-rules (§141-145) operate on the result of a previous `query` call, keeping the base validity question decoupled from the meta-question.
- **Deemed fulfillment** (`ConditionalAct`, §150): An `Adjudicate` instance calls `query` recursively with modified facts — a counterfactual ("what if the condition were fulfilled?"). Setting `condBadFaith = Nothing` removes the recursion trigger, bounding depth to exactly 1. This is a convention, not a compile-time guarantee; see [patterns catalog](docs/civil-act/patterns.md) for the full safety analysis.

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
