-- | Korean Civil Act type definitions.
--
-- For the full coverage summary, see "Deontic.Civil".
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
  , AgencyWithdrawalAct(..)
  , AgentLiabilityAct(..)
  , PartialInvalidityAct(..)
  , PartialInvalidityFacts(..)
  , CancellableAct(..)
  , CancellationFacts(..)
  , ConstructiveRatificationEvent(..)
  , ConditionalAct(..)
  , ConditionType(..)
  , ConditionState(..)
  , BadFaithKind(..)
  , ConditionalFacts(..)
  , CounterpartyKnowledge
  , HypotheticalIntent, Conversion
  , GeneralRatification, ConstructiveRatification
  , IllegalCondition, BadFaithCondition
  , module Data.Time.Calendar
  ) where

import Data.Set (Set)
import Data.Time.Calendar (Day, addGregorianYearsClip)
import Deontic.Core.Types (PersonId, ActId, Facts)
import Deontic.Core.Verdict (Verdict)

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

-- Layer tokens for agency remedies (무권대리 구제)
data CounterpartyKnowledge  -- §134 상대방의 악의

-- Layer tokens for partial invalidity (일부무효)
data HypotheticalIntent     -- §137 단서 가정적 의사
data Conversion             -- §138 무효행위의 전환

-- Layer tokens for cancellation (취소/추인)
data GeneralRatification       -- §143 추인
data ConstructiveRatification  -- §145 법정추인

-- Layer tokens for conditional acts (조건부 법률행위)
data IllegalCondition    -- §151 불법조건/기성조건
data BadFaithCondition   -- §150 반신의행위

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

-- | 상대방의 철회권 (민법 제134조)
data AgencyWithdrawalAct = AgencyWithdrawalAct
  { awPrincipal    :: PersonId
  , awCounterparty :: PersonId
  , awActId        :: ActId
  } deriving (Eq, Show)

-- | 무권대리인의 책임 (민법 제135조)
data AgentLiabilityAct = AgentLiabilityAct
  { alAgent        :: PersonId
  , alCounterparty :: PersonId
  , alActId        :: ActId
  } deriving (Eq, Show)

-- | 법률행위의 일부무효/전환/추인 (민법 제137조-제139조)
data PartialInvalidityAct = PartialInvalidityAct
  { piActId :: ActId
  } deriving (Eq, Show)

-- | 일부무효 판단에 필요한 사실관계
data PartialInvalidityFacts = PartialInvalidityFacts
  { pifPartVoid              :: Bool  -- 일부분이 무효
  , pifHypotheticalIntent    :: Bool  -- 무효부분 없이도 행위했을 것 (§137 단서)
  , pifMeetsOtherReqs        :: Bool  -- 다른 법률행위 요건 구비 (§138)
  , pifConversionIntent      :: Bool  -- 다른 행위를 의욕 (§138)
  , pifRatifiedWithKnowledge :: Bool  -- 무효 알고 추인 (§139)
  } deriving (Eq, Show)

-- | 취소할 수 있는 행위의 취소/추인 (민법 제141조, 제143조-제145조)
-- 다른 act type의 query 결과(Verdict)를 입력으로 받는 wrapper pattern.
data CancellableAct = CancellableAct
  { caActId        :: ActId
  , caPriorVerdict :: Verdict
  } deriving (Eq, Show)

-- | 취소/추인 판단에 필요한 사실관계
data CancellationFacts = CancellationFacts
  { cnfCancelled          :: Bool
  , cnfRatified           :: Bool
  , cnfCauseCeased        :: Bool
  , cnfRatifierIsGuardian :: Bool
  , cnfConstructive       :: Maybe ConstructiveRatificationEvent
  , cnfObjectionReserved  :: Bool
  } deriving (Eq, Show)

-- | 법정추인 사유 (민법 제145조)
data ConstructiveRatificationEvent
  = FullOrPartialPerformance
  | DemandForPerformance
  | Novation
  | SecurityProvision
  | RightAssignment
  | CompulsoryExecution
  deriving (Eq, Ord, Show)

-- | 조건부/기한부 법률행위 (민법 제147조, 제150조-제152조)
data ConditionalAct = ConditionalAct
  { condActId :: ActId
  } deriving (Eq, Show)

-- | 조건의 유형
data ConditionType
  = Suspensive  -- 정지조건 (§147①)
  | Resolutive  -- 해제조건 (§147②)
  | StartDate   -- 시기 (§152①)
  | EndDate     -- 종기 (§152②)
  deriving (Eq, Ord, Show)

-- | 조건의 상태
data ConditionState
  = CondPending     -- 미성취
  | CondFulfilled   -- 성취
  | CondImpossible  -- 성취 불가능
  | CondIllegal     -- 불법조건
  deriving (Eq, Ord, Show)

-- | 반신의행위의 유형 (민법 제150조)
data BadFaithKind
  = BadFaithPrevention  -- 조건 성취 방해 (§150①)
  | BadFaithCausation   -- 조건 성취 야기 (§150②)
  deriving (Eq, Ord, Show)

-- | 조건부 법률행위 판단에 필요한 사실관계
data ConditionalFacts = ConditionalFacts
  { condType     :: ConditionType
  , condState    :: ConditionState
  , condBadFaith :: Maybe BadFaithKind
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
  | CounterpartyKnewNoAuthority  -- §134 상대방이 대리권 없음을 안 때
  | AgentIsLimitedCapacity       -- §135② 대리인이 제한능력자
  | CounterpartyCouldHaveKnown   -- §135② 상대방이 알 수 있었을 때
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
type instance Facts AgencyWithdrawalAct   = Set CivilFact
type instance Facts AgentLiabilityAct     = Set CivilFact
type instance Facts PartialInvalidityAct  = PartialInvalidityFacts
type instance Facts CancellableAct        = CancellationFacts
type instance Facts ConditionalAct        = ConditionalFacts
