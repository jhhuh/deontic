module Deontic.Defeasible.Defeat
  ( DefeatGraph
  , buildDefeatGraph
  , isDefeated
  ) where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Deontic.Core.Types (ArticleRef)
import Deontic.Defeasible.Rule (Rule(..))

type DefeatGraph = Map.Map ArticleRef (Set.Set ArticleRef)

buildDefeatGraph :: [Rule] -> DefeatGraph
buildDefeatGraph rules =
  let applicableIds = Set.fromList (map ruleId rules)
  in Map.fromList
       [ (ruleId r, Set.fromList (filter (`Set.member` applicableIds) (defeatedBy r)))
       | r <- rules
       ]

isDefeated :: DefeatGraph -> ArticleRef -> Bool
isDefeated graph ref =
  case Map.lookup ref graph of
    Nothing      -> False
    Just defeats -> not (Set.null defeats)
