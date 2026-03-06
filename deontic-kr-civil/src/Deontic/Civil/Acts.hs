{-# LANGUAGE OverloadedStrings #-}
module Deontic.Civil.Acts
  ( actsCode
  , actsRules
  ) where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule
import Deontic.Query

actsRules :: [Rule]
actsRules =
  [ -- §103: void if against good morals
    Rule
      { ruleId = ArticleRef "민법" 103 Nothing
      , precondition = \fs -> Custom "contra-bonos-mores" `Set.member` fs
      , conclusion = JVoid [ArticleRef "민법" 103 Nothing]
      , defeatedBy = []
      }
  , -- §104: void if exploitative
    Rule
      { ruleId = ArticleRef "민법" 104 Nothing
      , precondition = \fs -> Custom "exploitative-act" `Set.member` fs
      , conclusion = JVoid [ArticleRef "민법" 104 Nothing]
      , defeatedBy = []
      }
  , -- §107①: valid despite hidden intention (when counterparty doesn't know)
    Rule
      { ruleId = ArticleRef "민법" 107 (Just 1)
      , precondition = \fs ->
          Custom "hidden-intention" `Set.member` fs
          && not (Custom "counterparty-knew" `Set.member` fs)
      , conclusion = JValid [ArticleRef "민법" 107 (Just 1)]
      , defeatedBy = [ArticleRef "민법" 107 (Just 2)]
      }
  , -- §107②: void if counterparty knew
    Rule
      { ruleId = ArticleRef "민법" 107 (Just 2)
      , precondition = \fs ->
          Custom "hidden-intention" `Set.member` fs
          && Custom "counterparty-knew" `Set.member` fs
      , conclusion = JVoid [ArticleRef "민법" 107 (Just 2)]
      , defeatedBy = []
      }
  ]

newtype ActsCode = ActsCode [Rule]

instance LegalCode ActsCode where
  codeRules (ActsCode rs) = rs

actsCode :: ActsCode
actsCode = ActsCode actsRules
