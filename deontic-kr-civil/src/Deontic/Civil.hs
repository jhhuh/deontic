-- | Korean Civil Act (민법) — Type-Level Stratified Deontic Encoding
--
-- = Coverage Summary
--
-- == 총칙 (General Provisions)
--
-- @
-- Module              Articles   Act Type              Layers                              Pattern
-- ──────────────────  ─────────  ────────────────────  ──────────────────────────────────  ─────────────────────────
-- Persons             §5         MinorAct              '[Proviso, Base]                    단서 override
-- Acts                §103-110   JuristicAct           '[SpecialRule, Proviso, Base]       3-layer stack
--                     §108       ShamAct               '[Proviso, Base]                    제3자 보호 (proviso)
--                     §109       MistakeAct            '[Proviso, Base]                    중과실 방어 (proviso)
--                     §110       FraudAct              '[Proviso, Base]                    제3자 사기 (proviso)
-- Agency              §114,§118  AuthAgencyAct         '[Proviso, Base]                    자기계약 금지
--                     §125-132   UnauthAgencyAct       '[ApparentAuth, Ratification, Base] 표현대리·추인
-- Rescission          §146       RescissionAct         '[Base]                             제척기간 (3년\/10년, §157 역산)
-- AgencyRemedies     §134-135   AgencyWithdrawalAct   '[CounterpartyKnowledge, Base]       상대방 악의 면책
--                               AgentLiabilityAct     '[Proviso, Base]                     대리인 면책
-- Invalidity         §137-139   PartialInvalidityAct  '[Conversion, HypotheticalIntent, Base] 일부무효·전환·추인
-- Cancellation       §141-145   CancellableAct        '[ConstructiveRatification, GeneralRatification, Base] wrapper pattern
-- ConditionalAct     §147-152   ConditionalAct        '[BadFaithCondition, IllegalCondition, Base] 정지\/해제조건·시기\/종기
-- @
--
-- == 물권법 (Property Law)
--
-- @
-- Module              Articles   Act Type              Layers                              Pattern
-- ──────────────────  ─────────  ────────────────────  ──────────────────────────────────  ─────────────────────────
-- Possession          §197,§200  PossessionAct         '[Rebuttal, Presumption]            반증에 의한 추정 번복
-- PropertyTransfer    §186-188   PropertyTransferAct   '[FormException, Base]              등기\/인도 + §187 예외
-- CoOwnership         §264       CoOwnershipAct        '[Base]                             전원 동의 (∀ quantification)
-- AcqPrescription     §245       AcqPrescriptionAct    '[ShortPrescription, Base]          20년\/10년 (§157 역산)
-- @
--
-- == 채권 총론 (General Obligations)
--
-- @
-- Module              Articles   Act Type              Layers                              Pattern
-- ──────────────────  ─────────  ────────────────────  ──────────────────────────────────  ─────────────────────────
-- Prescription        §162-174   PrescriptionAct       '[Interruption, Expiration]         시효만료 + 중단 (§157 역산)
-- DefaultObligation   §387-390   DefaultAct            '[CreditorDefense, Base]            이행지체·불능 + 채권자과실
-- @
--
-- == 채권 각론 (Specific Obligations)
--
-- @
-- Module              Articles   Act Type              Layers                              Pattern
-- ──────────────────  ─────────  ────────────────────  ──────────────────────────────────  ─────────────────────────
-- SaleWarranty        §580-582   WarrantyAct           '[BuyerKnowledge, Base]             하자담보 + 매수인 악의 면책
-- Lease               §618-640   LeaseAct              '[RenewalRight, Base]               묵시적 갱신 + 2기 연체 해지
-- @
--
-- == 불법행위 (Torts)
--
-- @
-- Module              Articles   Act Type              Layers                              Pattern
-- ──────────────────  ─────────  ────────────────────  ──────────────────────────────────  ─────────────────────────
-- Tort                §750,§396  TortAct               '[ContributoryNeg, Base]            4요건 + 과실상계
-- @
--
-- = Defeasibility Patterns Used
--
-- * __단서 override__ — Proviso layer overrides Base when exception applies (§5①)
-- * __3-layer stack__ — SpecialRule > Proviso > Base for graduated defeasibility (§103-107)
-- * __Rebuttable presumption__ — Presumption (default Valid) + Rebuttal override; absence = delegation (§197)
-- * __Lex specialis__ — FormException overrides general formality rule (§187 vs §186)
-- * __Temporal reasoning__ — 'Day' dates with 'addGregorianYearsClip' per §157 역산 (§146, §162, §245)
-- * __Universal quantification__ — @all@ over owners list in instance body (§264)
-- * __Verdict-conditional override__ — override fires only when @verdict prev == Void@ (§390, §396, §580②)
-- * __Multi-condition override__ — conjunction of several facts required (§639 묵시적 갱신)
-- * __Wrapper pattern__ — CancellableAct takes prior Verdict as input, applies meta-rules (§141-§145)
-- * __Deemed fulfillment__ — bad faith re-evaluates condition state via recursive query (§150)
--
-- = Fact Type Strategy
--
-- * @Set CivilFact@ — for boolean\/flag-based facts (§5, §103-110, §114-132, §186-188, §197-200)
-- * Domain records — for structured facts: 'PrescriptionFacts', 'RescissionFacts',
--   'AcqPrescFacts', 'DefaultFacts', 'WarrantyFacts', 'LeaseFacts', 'CoOwnershipFacts', 'TortFacts',
--   'PartialInvalidityFacts', 'CancellationFacts', 'ConditionalFacts'
--
-- = Test Coverage
--
-- 203 tests across unit tests (per-module), case studies (multi-issue disputes),
-- and real-case tests (based on 대법원 판례).
--
module Deontic.Civil
  ( -- * Re-exports
    module Deontic.Civil.Types
  , module Deontic.Civil.Persons
  , module Deontic.Civil.Acts
  , module Deontic.Civil.Agency
  , module Deontic.Civil.CoOwnership
  , module Deontic.Civil.Possession
  , module Deontic.Civil.Prescription
  , module Deontic.Civil.Tort
  , module Deontic.Civil.Rescission
  , module Deontic.Civil.PropertyTransfer
  , module Deontic.Civil.AcquisitivePrescription
  , module Deontic.Civil.DefaultObligation
  , module Deontic.Civil.SaleWarranty
  , module Deontic.Civil.Lease
  , module Deontic.Civil.AgencyRemedies
  , module Deontic.Civil.Invalidity
  , module Deontic.Civil.Cancellation
  , module Deontic.Civil.ConditionalAct
  , module Deontic.Civil.Render
  ) where

import Deontic.Civil.Types
import Deontic.Civil.Persons ()
import Deontic.Civil.Acts ()
import Deontic.Civil.Agency ()
import Deontic.Civil.CoOwnership ()
import Deontic.Civil.Possession ()
import Deontic.Civil.Prescription ()
import Deontic.Civil.Tort ()
import Deontic.Civil.Rescission ()
import Deontic.Civil.PropertyTransfer ()
import Deontic.Civil.AcquisitivePrescription ()
import Deontic.Civil.DefaultObligation ()
import Deontic.Civil.SaleWarranty ()
import Deontic.Civil.Lease ()
import Deontic.Civil.AgencyRemedies ()
import Deontic.Civil.Invalidity ()
import Deontic.Civil.Cancellation ()
import Deontic.Civil.ConditionalAct ()
import Deontic.Civil.Render
