{-# LANGUAGE OverloadedStrings #-}
module Deontic.Civil.Render
  ( KoreanRenderer(..)
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Deontic.Core.Types (ArticleRef(..))
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate (Judgment(..))
import Deontic.Render

data KoreanRenderer = KoreanRenderer

instance Renderer KoreanRenderer where
  renderJudgment _ j =
    let steps = judgmentSteps j
        v = case steps of
              [] -> Valid
              _  -> stepVerdict (last steps)
    in T.unlines $
         [ "판단: " <> verdictText v, "", "근거:" ]
         ++ concatMap renderStep steps
         ++ ["", "따라서, " <> verdictText v]

renderStep :: Step -> [Text]
renderStep s =
  [ "  " <> articleRefText (stepArticle s) <> kindText (stepKind s)
  , "  \"" <> stepSourceText s <> "\""
  , ""
  ]

kindText :: StepKind -> Text
kindText Applied    = "에 의하면,"
kindText Overridden = "에 의하여 이를 번복하면,"
kindText Delegated  = "을 검토하였으나 해당 없어,"

verdictText :: Verdict -> Text
verdictText Valid    = "본 법률행위는 유효하다."
verdictText Void     = "본 법률행위는 무효이다."
verdictText Voidable = "본 법률행위는 취소할 수 있다."

articleRefText :: ArticleRef -> Text
articleRefText ref =
  "민법 제" <> T.pack (show (articleNumber ref)) <> "조"
  <> maybe "" (\p -> " 제" <> T.pack (show p) <> "항") (articleParagraph ref)
