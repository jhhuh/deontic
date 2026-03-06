module Deontic.Civil.Types
  ( MinorAct(..)
  , JuristicAct(..)
  , ShamAct(..)
  , MistakeAct(..)
  , FraudAct(..)
  , CivilFact(..)
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
  deriving (Eq, Ord, Show)

type instance Facts MinorAct    = Set CivilFact
type instance Facts JuristicAct = Set CivilFact
type instance Facts ShamAct     = Set CivilFact
type instance Facts MistakeAct  = Set CivilFact
type instance Facts FraudAct    = Set CivilFact
