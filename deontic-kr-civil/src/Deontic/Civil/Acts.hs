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

-- | 민법 제4장 법률행위 (Juristic Acts)
actsRules :: [Rule]
actsRules =
  [ -- 제103조(반사회질서의 법률행위)
    Rule
      { ruleId = ArticleRef "민법" 103 Nothing
      , sourceText = "선량한 풍속 기타 사회질서에 위반한 사항을 내용으로 하는 \
                     \법률행위는 무효로 한다."
      , precondition = \fs -> Custom "contra-bonos-mores" `Set.member` fs
      , conclusion = JVoid [ArticleRef "민법" 103 Nothing]
      , defeatedBy = []
      }
  , -- 제104조(불공정한 법률행위)
    Rule
      { ruleId = ArticleRef "민법" 104 Nothing
      , sourceText = "당사자의 궁박, 경솔 또는 무경험으로 인하여 현저하게 \
                     \공정을 잃은 법률행위는 무효로 한다."
      , precondition = \fs -> Custom "exploitative-act" `Set.member` fs
      , conclusion = JVoid [ArticleRef "민법" 104 Nothing]
      , defeatedBy = []
      }
  , -- 제107조(비진의 의사표시) ①
    Rule
      { ruleId = ArticleRef "민법" 107 (Just 1)
      , sourceText = "의사표시는 표의자가 진의아님을 알고 한 것이라도 \
                     \그 효력에 영향을 미치지 아니한다."
      , precondition = \fs ->
          Custom "hidden-intention" `Set.member` fs
          && not (Custom "counterparty-knew" `Set.member` fs)
      , conclusion = JValid [ArticleRef "민법" 107 (Just 1)]
      , defeatedBy = [ArticleRef "민법" 107 (Just 2)]
      }
  , -- 제107조(비진의 의사표시) ② — 상대방이 알았을 때
    Rule
      { ruleId = ArticleRef "민법" 107 (Just 2)
      , sourceText = "그러나 상대방이 표의자의 진의아님을 알았거나 \
                     \알 수 있었을 경우에는 무효로 한다."
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
