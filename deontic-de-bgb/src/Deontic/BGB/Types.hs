module Deontic.BGB.Types
  ( CapacityAct(..)
  , BGBFact(..)
  , LimitedCapacity
  ) where

import Data.Set (Set)
import Deontic.Core.Types (PersonId, ActId, Facts)

-- | Geschäftsfähigkeit — Capacity to contract (BGB §104-§113)
data CapacityAct = CapacityAct
  { caActor :: PersonId
  , caActId :: ActId
  } deriving (Eq, Show)

-- | Layer token for limited capacity (beschränkte Geschäftsfähigkeit)
data LimitedCapacity  -- §106-§113

-- | BGB-specific facts
data BGBFact
  -- §104 Geschäftsunfähigkeit
  = UnderSeven PersonId           -- unter sieben Jahren
  | PermanentlyIncapable PersonId -- dauerhafte Störung der Geistestätigkeit
  -- §106-§113 beschränkte Geschäftsfähigkeit
  | IsMinor PersonId              -- Minderjährig (7-17)
  | LegalRepConsent PersonId ActId -- Einwilligung des gesetzlichen Vertreters
  | PurelyBeneficial              -- lediglich rechtlichen Vorteil (§107)
  | PocketMoney                   -- Taschengeld (§110)
  deriving (Eq, Ord, Show)

type instance Facts CapacityAct = Set BGBFact
