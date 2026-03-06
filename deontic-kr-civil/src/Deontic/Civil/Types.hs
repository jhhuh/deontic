module Deontic.Civil.Types
  ( MinorAct(..)
  , JuristicAct(..)
  , ShamAct(..)
  , MistakeAct(..)
  , FraudAct(..)
  , AuthAgencyAct(..)
  , UnauthAgencyAct(..)
  , CivilFact(..)
  , Ratification, ApparentAuth
  ) where

import Data.Set (Set)
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

-- Layer tokens for agency
data Ratification    -- 추인 (§130, §132)
data ApparentAuth    -- 표현대리 (§125-129)

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
  deriving (Eq, Ord, Show)

type instance Facts MinorAct    = Set CivilFact
type instance Facts JuristicAct = Set CivilFact
type instance Facts ShamAct     = Set CivilFact
type instance Facts MistakeAct  = Set CivilFact
type instance Facts FraudAct         = Set CivilFact
type instance Facts AuthAgencyAct    = Set CivilFact
type instance Facts UnauthAgencyAct  = Set CivilFact
