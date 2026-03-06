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
--
-- = Fact Type Strategy
--
-- * @Set CivilFact@ — for boolean\/flag-based facts (§5, §103-110, §114-132, §186-188, §197-200)
-- * Domain records — for structured facts: 'PrescriptionFacts', 'RescissionFacts',
--   'AcqPrescFacts', 'DefaultFacts', 'WarrantyFacts', 'LeaseFacts', 'CoOwnershipFacts', 'TortFacts'
--
-- = Test Coverage
--
-- 166 tests across unit tests (per-module), case studies (multi-issue disputes),
-- and real-case tests (based on 대법원 판례).
--
module Deontic.Civil.Types
  ( MinorAct(..)
  , JuristicAct(..)
  , ShamAct(..)
  , MistakeAct(..)
  , FraudAct(..)
  , AuthAgencyAct(..)
  , UnauthAgencyAct(..)
  , PossessionAct(..)
  , PrescriptionAct(..)
  , CoOwnershipAct(..)
  , TortAct(..)
  , RescissionAct(..)
  , PropertyTransferAct(..)
  , AcqPrescriptionAct(..)
  , DefaultAct(..)
  , WarrantyAct(..)
  , LeaseAct(..)
  , CivilFact(..)
  , PrescriptionFacts(..)
  , CoOwnershipFacts(..)
  , TortFacts(..)
  , RescissionFacts(..)
  , AcqPrescFacts(..)
  , DefaultFacts(..)
  , WarrantyFacts(..)
  , LeaseFacts(..)
  , Ratification, ApparentAuth
  , Presumption, Rebuttal
  , Expiration, Interruption
  , ContributoryNeg
  , FormException
  , ShortPrescription
  , CreditorDefense
  , BuyerKnowledge
  , RenewalRight
  , module Data.Time.Calendar
  ) where

import Data.Set (Set)
import Data.Time.Calendar (Day, addGregorianYearsClip)
import Deontic.Core.Types (PersonId, ActId, Facts)

-- | 미성년자의 법률행위 (민법 제5조)
data MinorAct = MinorAct
  { maActor :: PersonId
  , maActId :: ActId
  } deriving (Eq, Show)

-- | 일반 법률행위 (민법 제103조-제107조)
data JuristicAct = JuristicAct
  { jaActor :: PersonId
  , jaActId :: ActId
  } deriving (Eq, Show)

-- | 통정허위표시 (민법 제108조)
data ShamAct = ShamAct
  { saActor :: PersonId
  , saActId :: ActId
  } deriving (Eq, Show)

-- | 착오에 의한 의사표시 (민법 제109조)
data MistakeAct = MistakeAct
  { mkActor :: PersonId
  , mkActId :: ActId
  } deriving (Eq, Show)

-- | 사기·강박에 의한 의사표시 (민법 제110조)
data FraudAct = FraudAct
  { faActor :: PersonId
  , faActId :: ActId
  } deriving (Eq, Show)

-- | 유권대리 (민법 제114조, 제118조)
data AuthAgencyAct = AuthAgencyAct
  { aaaPrincipal :: PersonId  -- 본인
  , aaaAgent     :: PersonId  -- 대리인
  , aaaActId     :: ActId
  } deriving (Eq, Show)

-- | 무권대리 (민법 제130조, 제125-129조, 제132조)
data UnauthAgencyAct = UnauthAgencyAct
  { uaaPrincipal :: PersonId  -- 본인
  , uaaAgent     :: PersonId  -- 대리인
  , uaaActId     :: ActId
  } deriving (Eq, Show)

-- | 점유권 추정 (민법 제197조, 제200조)
data PossessionAct = PossessionAct
  { paActor  :: PersonId
  , paActId  :: ActId
  } deriving (Eq, Show)

-- | 소멸시효 (민법 제162조, 제168조, 제174조)
data PrescriptionAct = PrescriptionAct
  { prCreditor :: PersonId
  , prClaimId  :: ActId
  } deriving (Eq, Show)

-- | 소멸시효 판단에 필요한 시간적 사실관계
-- §157에 따라 역(曆)에 의한 계산: 기간을 연으로 정한 때에는
-- 기산일에 해당하는 날의 전일로 만료한다.
data PrescriptionFacts = PrescriptionFacts
  { pfClaimDate     :: Day        -- 채권 발생일
  , pfCurrentDate   :: Day        -- 판단 시점
  , pfPeriodYears   :: Int        -- 소멸시효기간 (년)
  , pfInterruptedOn :: Maybe Day  -- 중단 시점, Nothing = 중단 없음
  } deriving (Eq, Show)

-- | 공유물의 처분 (민법 제264조)
data CoOwnershipAct = CoOwnershipAct
  { coActId :: ActId
  } deriving (Eq, Show)

-- | 공유물 처분 판단에 필요한 사실관계
-- (demonstrates universal quantification: ∀ owner ∈ owners, owner ∈ consented)
data CoOwnershipFacts = CoOwnershipFacts
  { cofOwners    :: [PersonId]       -- 공유자 전원
  , cofConsented :: Set PersonId     -- 동의한 공유자
  } deriving (Eq, Show)

-- | 불법행위 (민법 제750조, 제763조→제396조)
data TortAct = TortAct
  { taVictim    :: PersonId
  , taTortfeasor :: PersonId
  , taActId     :: ActId
  } deriving (Eq, Show)

-- | 불법행위 판단에 필요한 사실관계
data TortFacts = TortFacts
  { tfFault     :: Bool   -- 고의 또는 과실
  , tfUnlawful  :: Bool   -- 위법성
  , tfDamage    :: Bool   -- 손해 발생
  , tfCausation :: Bool   -- 인과관계
  , tfVictimNeg :: Bool   -- 피해자의 과실 (과실상계 §763→§396)
  } deriving (Eq, Show)

-- Layer tokens for agency
data Ratification    -- 추인 (§130, §132)
data ApparentAuth    -- 표현대리 (§125-129)

-- Layer tokens for rebuttable presumptions
data Presumption     -- 추정 (default rule)
data Rebuttal        -- 반증 (rebuttal)

-- Layer tokens for prescription (소멸시효)
data Expiration      -- 시효만료 (§162)
data Interruption    -- 시효중단 (§168, §174)

-- Layer tokens for tort (불법행위)
data ContributoryNeg -- 과실상계 (§763→§396)

-- Layer tokens for property transfer (물권변동)
data FormException   -- §187 등기 없이 물권변동 (상속, 판결 등)

-- Layer tokens for acquisitive prescription (취득시효)
data ShortPrescription -- §245② 단기 취득시효 (10년, 선의·무과실)

-- Layer tokens for default obligation (채무불이행)
data CreditorDefense   -- §390 채권자 과실

-- Layer tokens for sale warranty (하자담보)
data BuyerKnowledge    -- §580② 매수인 악의·과실

-- Layer tokens for lease (임대차)
data RenewalRight      -- §639 묵시적 갱신

-- | 취소의 제척기간 (민법 제146조)
data RescissionAct = RescissionAct
  { raActor :: PersonId
  , raActId :: ActId
  } deriving (Eq, Show)

-- | 제척기간 판단에 필요한 시간적 사실관계
-- §157에 따라 역(曆)에 의한 계산.
data RescissionFacts = RescissionFacts
  { rfKnowledgeDate :: Day  -- 취소원인을 안 날
  , rfActDate       :: Day  -- 법률행위가 있은 날
  , rfCurrentDate   :: Day  -- 판단 시점
  } deriving (Eq, Show)

-- | 물권변동 (민법 제186조, 제187조, 제188조)
data PropertyTransferAct = PropertyTransferAct
  { ptActor :: PersonId
  , ptActId :: ActId
  } deriving (Eq, Show)

-- | 취득시효 (민법 제245조, 제246조)
data AcqPrescriptionAct = AcqPrescriptionAct
  { apActor :: PersonId
  , apActId :: ActId
  } deriving (Eq, Show)

-- | 취득시효 판단에 필요한 사실관계
-- §157에 따라 역(曆)에 의한 계산.
data AcqPrescFacts = AcqPrescFacts
  { apfStartDate       :: Day   -- 점유 개시일
  , apfCurrentDate     :: Day   -- 판단 시점
  , apfGoodFaith       :: Bool  -- 선의
  , apfNoNegligence    :: Bool  -- 무과실
  , apfPeaceful        :: Bool  -- 평온
  , apfPublic          :: Bool  -- 공연
  , apfSelfPossession  :: Bool  -- 자주점유 (소유의 의사)
  } deriving (Eq, Show)

-- | 채무불이행 (민법 제387조-제390조)
data DefaultAct = DefaultAct
  { dfCreditor :: PersonId
  , dfDebtor   :: PersonId
  , dfActId    :: ActId
  } deriving (Eq, Show)

-- | 채무불이행 판단에 필요한 사실관계
data DefaultFacts = DefaultFacts
  { dfPerformanceDue :: Bool  -- 이행기 도래
  , dfNonPerformance :: Bool  -- 불이행
  , dfDebtorFault    :: Bool  -- 채무자 귀책사유
  , dfImpossible     :: Bool  -- 이행불능
  , dfCreditorFault  :: Bool  -- 채권자 과실 (§390)
  } deriving (Eq, Show)

-- | 하자담보책임 (민법 제580조-제582조)
data WarrantyAct = WarrantyAct
  { waActor :: PersonId
  , waActId :: ActId
  } deriving (Eq, Show)

-- | 하자담보 판단에 필요한 사실관계
data WarrantyFacts = WarrantyFacts
  { wfDefectExists   :: Bool  -- 하자 존재
  , wfSignificant    :: Bool  -- 중대한 하자 (계약목적 달성 불가)
  , wfBuyerKnew      :: Bool  -- 매수인이 알았거나 과실로 몰랐음
  , wfNotifiedInTime :: Bool  -- 6개월 내 통지 (§582)
  } deriving (Eq, Show)

-- | 임대차 (민법 제618조, 제623조, 제639조, 제640조)
data LeaseAct = LeaseAct
  { laLessor :: PersonId
  , laLessee :: PersonId
  , laActId  :: ActId
  } deriving (Eq, Show)

-- | 임대차 판단에 필요한 사실관계
data LeaseFacts = LeaseFacts
  { lfValidContract  :: Bool  -- 유효한 임대차계약
  , lfRentPaid       :: Bool  -- 차임 지급
  , lfPeriodExpired  :: Bool  -- 기간 만료
  , lfContinuedUse   :: Bool  -- 기간 만료 후 계속 사용
  , lfNoObjection    :: Bool  -- 임대인 이의 없음
  , lfTwoRentsLate   :: Bool  -- 2기의 차임 연체 (§640)
  } deriving (Eq, Show)

-- | 민법 사실관계 (Korean Civil Act facts)
data CivilFact
  -- 인적 사항
  = IsNaturalPerson PersonId
  | IsJuristicPerson PersonId
  | IsMinor PersonId
  | IsAdult PersonId
  | HasGuardian PersonId PersonId
  | HasConsent PersonId ActId
  | PerformsAct PersonId ActId
  -- §5 단서
  | MerelyAcquiresRight
  -- §103, §104
  | ContraBonorsMores
  | ExploitativeAct
  -- §107
  | HiddenIntention
  | CounterpartyKnew
  -- §108
  | BonaFideThirdParty
  -- §109
  | GrossNegligence
  -- §110
  | ThirdPartyFraud
  | CounterpartyKnewFraud
  -- §118 대리
  | SelfDealing
  -- §125-129 표현대리
  | IndicatedAuthority        -- §125 대리권수여의 표시
  | ExceededScope              -- §126 권한을 넘은 행위
  | AuthorityExpired           -- §129 대리권 소멸
  -- §130, §132 무권대리
  | Ratified                   -- 추인
  -- §197, §200 점유 추정의 반증
  | BadFaith                   -- 악의 (반증: §197)
  | ViolentPossession          -- 강폭 점유 (반증: §197)
  | ClandestinePossession      -- 은비 점유 (반증: §197)
  | NoOwnershipIntent          -- 타주점유 (반증: §200)
  -- §186-188 물권변동
  | HasRegistration             -- 등기 완료
  | HasDelivery                 -- 인도 완료
  | IsRealProperty              -- 부동산
  | IsMovableProperty           -- 동산
  | ByInheritance               -- 상속에 의한 물권변동 (§187)
  | ByCourtOrder                -- 판결에 의한 물권변동 (§187)
  | ByPublicAuction             -- 공매에 의한 물권변동 (§187)
  | ByExpropriation             -- 수용에 의한 물권변동 (§187)
  deriving (Eq, Ord, Show)

type instance Facts MinorAct    = Set CivilFact
type instance Facts JuristicAct = Set CivilFact
type instance Facts ShamAct     = Set CivilFact
type instance Facts MistakeAct  = Set CivilFact
type instance Facts FraudAct         = Set CivilFact
type instance Facts AuthAgencyAct    = Set CivilFact
type instance Facts UnauthAgencyAct  = Set CivilFact
type instance Facts PossessionAct    = Set CivilFact
type instance Facts PrescriptionAct  = PrescriptionFacts
type instance Facts CoOwnershipAct   = CoOwnershipFacts
type instance Facts TortAct          = TortFacts
type instance Facts RescissionAct    = RescissionFacts
type instance Facts PropertyTransferAct = Set CivilFact
type instance Facts AcqPrescriptionAct  = AcqPrescFacts
type instance Facts DefaultAct       = DefaultFacts
type instance Facts WarrantyAct      = WarrantyFacts
type instance Facts LeaseAct         = LeaseFacts
