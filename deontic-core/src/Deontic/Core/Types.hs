{-# LANGUAGE OverloadedStrings #-}
module Deontic.Core.Types
  ( PersonId(..), ActId(..), ThingId(..)
  , ArticleRef(..)
  , Fact(..), Facts
  ) where

import Data.Text (Text)
import Data.Set (Set)

newtype PersonId = PersonId Text deriving (Eq, Ord, Show)
newtype ActId    = ActId Text    deriving (Eq, Ord, Show)
newtype ThingId  = ThingId Text  deriving (Eq, Ord, Show)

data ArticleRef = ArticleRef
  { articleStatute   :: Text
  , articleNumber    :: Int
  , articleParagraph :: Maybe Int
  } deriving (Eq, Ord, Show)

data Fact
  = IsNaturalPerson PersonId
  | IsJuristicPerson PersonId
  | IsMinor PersonId
  | IsAdult PersonId
  | HasGuardian PersonId PersonId
  | HasConsent PersonId ActId
  | PerformsAct PersonId ActId
  | Custom Text
  deriving (Eq, Ord, Show)

type Facts = Set Fact
