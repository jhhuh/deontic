{-# LANGUAGE OverloadedStrings #-}
module Deontic.Render
  ( Renderer(..)
  , judgmentSteps
  , Step(..)
  , StepKind(..)
  ) where

import Data.Text (Text)
import Deontic.Core.Types (ArticleRef)
import Deontic.Core.Verdict (Verdict)
import Deontic.Core.Adjudicate (Judgment(..))

-- | A single step in the reasoning chain
data Step = Step
  { stepKind       :: StepKind
  , stepVerdict    :: Verdict
  , stepArticle    :: ArticleRef
  , stepSourceText :: Text
  } deriving (Eq, Show)

data StepKind = Applied | Overridden | Delegated
  deriving (Eq, Show)

-- | Extract the reasoning steps from a Judgment GADT (bottom-up)
judgmentSteps :: Judgment layers -> [Step]
judgmentSteps (JBase v ref txt) =
  [Step Applied v ref txt]
judgmentSteps (JOverride prev v ref txt) =
  judgmentSteps prev ++ [Step Overridden v ref txt]
judgmentSteps (JDelegate prev) =
  judgmentSteps prev

-- | Renderer typeclass — jurisdiction-specific output
class Renderer r where
  renderJudgment :: r -> Judgment layers -> Text
