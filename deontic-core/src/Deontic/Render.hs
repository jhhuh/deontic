{-# LANGUAGE OverloadedStrings #-}
module Deontic.Render
  ( Renderer(..)
  , ExplainedResult(..)
  , explain
  ) where

import Data.Text (Text)
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule

-- | An explained query result: the judgment, the rule that produced it,
--   and the facts that were present when it fired.
data ExplainedResult = ExplainedResult
  { erJudgment  :: Judgment
  , erRule       :: Rule
  , erFacts      :: Facts      -- ^ all input facts (renderer filters relevant ones)
  }

-- | Renderer turns explained results into natural language text.
--   Implemented per-jurisdiction (e.g. Korean, English).
class Renderer r where
  renderResult :: r -> ExplainedResult -> Text

-- | Given rules and facts, produce explained results for all undefeated conclusions.
explain :: [Rule] -> Facts -> [ExplainedResult]
explain rules facts =
  let applicableRules = filter (`applicable` facts) rules
      graph = buildDefeatGraphFor applicableRules
      undefeated = filter (\r -> not (isDefeatedIn graph (ruleId r))) applicableRules
  in [ ExplainedResult (conclusion r) r facts | r <- undefeated ]

-- Internal: simplified defeat check inlined to avoid circular imports
buildDefeatGraphFor :: [Rule] -> [(ArticleRef, [ArticleRef])]
buildDefeatGraphFor rules =
  let ids = Set.fromList (map ruleId rules)
  in [ (ruleId r, filter (`Set.member` ids) (defeatedBy r)) | r <- rules ]

isDefeatedIn :: [(ArticleRef, [ArticleRef])] -> ArticleRef -> Bool
isDefeatedIn graph ref =
  case lookup ref graph of
    Nothing -> False
    Just ds -> not (null ds)
