module Deontic.Core.Capacity
  ( CapacityLevel(..)
  , LegalSubject(..)
  ) where

import Deontic.Core.Types (Facts)

data CapacityLevel = None | Limited | Full
  deriving (Eq, Ord, Show)

class LegalSubject a where
  capacityLevel :: a -> Facts -> CapacityLevel
