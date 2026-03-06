module Deontic.Query
  ( LegalCode(..)
  , query
  , SimpleCode(..)
  ) where

import Deontic.Core.Types (ArticleRef, Facts)
import Deontic.Core.Judgment (Judgment)
import Deontic.Defeasible.Rule (Rule)
import Deontic.Defeasible.Resolve (resolve)

class LegalCode code where
  codeRules :: code -> [Rule]

query :: LegalCode code => code -> Facts -> [(Judgment, ArticleRef)]
query code facts = resolve (codeRules code) facts

newtype SimpleCode = SimpleCode [Rule]

instance LegalCode SimpleCode where
  codeRules (SimpleCode rs) = rs
