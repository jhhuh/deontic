module Deontic.Core.Layer
  ( Base, Proviso, SpecialRule
  , Resolvable
  ) where

-- | 원칙 (general rule)
data Base

-- | 단서 (proviso/exception)
data Proviso

-- | 특칙 (lex specialis)
data SpecialRule

-- | Maps an act type to its full override layer stack.
-- Each act type provides a type instance.
type family Resolvable act :: [*]
