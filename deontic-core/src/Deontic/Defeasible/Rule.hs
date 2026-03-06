module Deontic.Defeasible.Rule
  ( Rule(..)
  , applicable
  ) where

import Deontic.Core.Types (ArticleRef, Facts)
import Deontic.Core.Judgment (Judgment)

data Rule = Rule
  { ruleId       :: ArticleRef
  , precondition :: Facts -> Bool
  , conclusion   :: Judgment
  , defeatedBy   :: [ArticleRef]
  }

applicable :: Rule -> Facts -> Bool
applicable rule facts = precondition rule facts
