{-# LANGUAGE OverloadedStrings #-}
module Deontic.Civil.Persons
  ( personsCode
  , personsRules
  ) where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule
import Deontic.Query

personsRules :: [Rule]
personsRules =
  [ -- §5①: minor's juristic act without consent is voidable
    Rule
      { ruleId = ArticleRef "민법" 5 (Just 1)
      , precondition = \fs ->
          any isMinorFact (Set.toList fs)
          && not (hasConsentInFacts fs)
      , conclusion = JVoidable [ArticleRef "민법" 5 (Just 1)]
      , defeatedBy = [ArticleRef "민법" 5 (Just 2)]
      }
  , -- §5②: acts merely acquiring rights are valid without consent
    Rule
      { ruleId = ArticleRef "민법" 5 (Just 2)
      , precondition = \fs ->
          any isMinorFact (Set.toList fs)
          && Custom "merely-acquires-right" `Set.member` fs
      , conclusion = JValid [ArticleRef "민법" 5 (Just 2)]
      , defeatedBy = []
      }
  , -- §5① (consent path): minor with guardian consent is valid
    Rule
      { ruleId = ArticleRef "민법" 5 (Just 1)
      , precondition = \fs ->
          any isMinorFact (Set.toList fs)
          && hasConsentInFacts fs
      , conclusion = JValid [ArticleRef "민법" 5 (Just 1)]
      , defeatedBy = []
      }
  ]

isMinorFact :: Fact -> Bool
isMinorFact (IsMinor _) = True
isMinorFact _           = False

hasConsentInFacts :: Facts -> Bool
hasConsentInFacts fs = any isConsent (Set.toList fs)
  where
    isConsent (HasConsent _ _) = True
    isConsent _                = False

newtype PersonsCode = PersonsCode [Rule]

instance LegalCode PersonsCode where
  codeRules (PersonsCode rs) = rs

personsCode :: PersonsCode
personsCode = PersonsCode personsRules
