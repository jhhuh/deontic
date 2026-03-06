-- | Layer tokens and the 'Resolvable' type family.
--
-- Layers are uninhabited types that serve as type-level tags
-- in the 'Judgment' GADT. Jurisdictions may define their own
-- layer tokens in addition to the built-in ones.
module Deontic.Core.Layer
  ( Base, Proviso, SpecialRule
  , Resolvable
  ) where

import Data.Kind (Type)

-- | 원칙 (general rule)
data Base

-- | 단서 (proviso/exception)
data Proviso

-- | 특칙 (lex specialis)
data SpecialRule

-- | Maps an act type to its full override layer stack.
-- Each act type provides a type instance.
type family Resolvable act :: [Type]
