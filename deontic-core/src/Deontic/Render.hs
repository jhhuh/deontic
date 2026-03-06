{-# LANGUAGE OverloadedStrings #-}
-- | Rendering judgments as human-readable reasoning chains.
--
-- The 'Step' type extracts the reasoning chain from a 'Judgment' GADT.
-- The 'Renderer' typeclass allows jurisdiction-specific output formats.
module Deontic.Render
  ( Renderer(..)
  , judgmentSteps
  , someJudgmentSteps
  , Step(..)
  , StepKind(..)
  ) where

import Data.Text (Text)
import Deontic.Core.Types (ArticleRef)
import Deontic.Core.Verdict (Verdict)
import Deontic.Core.Adjudicate (Judgment(..), SomeJudgment(..))

-- | A single step in the reasoning chain
data Step = Step
  { stepKind       :: StepKind
  , stepVerdict    :: Verdict
  , stepArticle    :: ArticleRef
  , stepSourceText :: Text
  } deriving (Eq, Show)

-- | What happened at each layer of the reasoning chain.
data StepKind
  = Applied    -- ^ Base rule was applied directly
  | Overridden -- ^ This layer overrode a lower layer's verdict
  | Delegated  -- ^ This layer delegated to a lower layer (no override)
  deriving (Eq, Show)

-- | Extract the reasoning steps from a Judgment GADT (bottom-up)
judgmentSteps :: Judgment layers -> [Step]
judgmentSteps (JBase v ref txt) =
  [Step Applied v ref txt]
judgmentSteps (JOverride prev v ref txt) =
  judgmentSteps prev ++ [Step Overridden v ref txt]
judgmentSteps (JDelegate prev) =
  judgmentSteps prev

-- | Extract steps from an existentially-wrapped judgment
someJudgmentSteps :: SomeJudgment -> [Step]
someJudgmentSteps (SomeJudgment j) = judgmentSteps j

-- | Renderer typeclass — jurisdiction-specific output
class Renderer r where
  renderJudgment :: r -> Judgment layers -> Text
