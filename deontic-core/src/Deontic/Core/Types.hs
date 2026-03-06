-- | Core types for the deontic logic framework.
--
-- These are jurisdiction-agnostic identifiers and references
-- shared across all encodings.
module Deontic.Core.Types
  ( PersonId(..), ActId(..), ThingId(..)
  , ArticleRef(..)
  , Facts
  ) where

import Data.Kind (Type)
import Data.Text (Text)

-- | A person identifier (당사자).
newtype PersonId = PersonId Text deriving (Eq, Ord, Show)
-- | An act identifier (법률행위).
newtype ActId    = ActId Text    deriving (Eq, Ord, Show)
-- | A thing/object identifier (물건).
newtype ThingId  = ThingId Text  deriving (Eq, Ord, Show)

-- | Reference to a specific article in a statute.
data ArticleRef = ArticleRef
  { articleStatute   :: Text      -- ^ Statute name (e.g., "민법", "BGB")
  , articleNumber    :: Int       -- ^ Article number
  , articleParagraph :: Maybe Int -- ^ Paragraph number, if any
  } deriving (Eq, Ord, Show)

-- | Open type family: each jurisdiction defines its own fact type
type family Facts act :: Type
