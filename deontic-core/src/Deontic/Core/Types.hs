module Deontic.Core.Types
  ( PersonId(..), ActId(..), ThingId(..)
  , ArticleRef(..)
  , Facts
  ) where

import Data.Kind (Type)
import Data.Text (Text)

newtype PersonId = PersonId Text deriving (Eq, Ord, Show)
newtype ActId    = ActId Text    deriving (Eq, Ord, Show)
newtype ThingId  = ThingId Text  deriving (Eq, Ord, Show)

data ArticleRef = ArticleRef
  { articleStatute   :: Text
  , articleNumber    :: Int
  , articleParagraph :: Maybe Int
  } deriving (Eq, Ord, Show)

-- | Open type family: each jurisdiction defines its own fact type
type family Facts act :: Type
