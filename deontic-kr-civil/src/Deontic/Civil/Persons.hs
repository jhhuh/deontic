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

-- | 민법 제2장 인 (Persons)
personsRules :: [Rule]
personsRules =
  [ -- 제5조(미성년자의 법률행위) ①
    Rule
      { ruleId = ArticleRef "민법" 5 (Just 1)
      , sourceText = "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다. \
                     \다만, 권리만을 얻거나 의무만을 면하는 법률행위는 그러하지 아니하다."
      , precondition = \fs ->
          any isMinorFact (Set.toList fs)
          && not (hasConsentInFacts fs)
      , conclusion = JVoidable [ArticleRef "민법" 5 (Just 1)]
      , defeatedBy = [ArticleRef "민법" 5 (Just 2)]
      }
  , -- 제5조(미성년자의 법률행위) ① 단서
    Rule
      { ruleId = ArticleRef "민법" 5 (Just 2)
      , sourceText = "권리만을 얻거나 의무만을 면하는 법률행위는 그러하지 아니하다."
      , precondition = \fs ->
          any isMinorFact (Set.toList fs)
          && Custom "merely-acquires-right" `Set.member` fs
      , conclusion = JValid [ArticleRef "민법" 5 (Just 2)]
      , defeatedBy = []
      }
  , -- 제5조(미성년자의 법률행위) ① — 동의를 얻은 경우
    Rule
      { ruleId = ArticleRef "민법" 5 (Just 1)
      , sourceText = "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다."
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
