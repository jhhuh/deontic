module Deontic.Defeasible.Resolve
  ( resolve
  ) where

import Deontic.Core.Types (ArticleRef, Facts)
import Deontic.Core.Judgment (Judgment)
import Deontic.Defeasible.Rule (Rule(..), applicable)
import Deontic.Defeasible.Defeat (buildDefeatGraph, isDefeated)

resolve :: [Rule] -> Facts -> [(Judgment, ArticleRef)]
resolve rules facts =
  let applicableRules = filter (`applicable` facts) rules
      graph = buildDefeatGraph applicableRules
      undefeated = filter (\r -> not (isDefeated graph (ruleId r))) applicableRules
  in [(conclusion r, ruleId r) | r <- undefeated]
