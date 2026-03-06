{-# LANGUAGE OverloadedStrings #-}
module Deontic.Civil.Render
  ( KoreanRenderer(..)
  , renderKorean
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule (Rule(..))
import Deontic.Render

-- | Korean legal sentence renderer
data KoreanRenderer = KoreanRenderer

instance Renderer KoreanRenderer where
  renderResult _ er = renderKorean er

-- | Render an explained result as a Korean legal reasoning paragraph.
renderKorean :: ExplainedResult -> Text
renderKorean er =
  let j = erJudgment er
      r = erRule er
      ref = ruleId r
      facts = erFacts er
  in T.unlines
       [ "판단: " <> judgmentText j
       , ""
       , "근거:"
       , "  " <> articleRefText ref <> "에 의하면,"
       , "  \"" <> sourceText r <> "\""
       , ""
       , "  본 건에서:"
       , renderFactLines facts
       , ""
       , "  따라서, " <> articleRefText ref <> "에 의하여 " <> judgmentText j
       ]

judgmentText :: Judgment -> Text
judgmentText (JValid _)    = "본 법률행위는 유효하다."
judgmentText (JVoid _)     = "본 법률행위는 무효이다."
judgmentText (JVoidable _) = "본 법률행위는 취소할 수 있다."
judgmentText (JAmbiguous _) = "본 법률행위에 대하여 상충하는 판단이 존재한다."

articleRefText :: ArticleRef -> Text
articleRefText ref =
  "민법 제" <> T.pack (show (articleNumber ref)) <> "조"
  <> maybe "" (\p -> " 제" <> T.pack (show p) <> "항") (articleParagraph ref)

renderFactLines :: Facts -> Text
renderFactLines facts =
  T.intercalate "\n" [ "  - " <> renderFact f | f <- Set.toList facts ]

renderFact :: Fact -> Text
renderFact (IsNaturalPerson (PersonId p)) = p <> "은(는) 자연인이다."
renderFact (IsJuristicPerson (PersonId p)) = p <> "은(는) 법인이다."
renderFact (IsMinor (PersonId p)) = p <> "은(는) 미성년자이다."
renderFact (IsAdult (PersonId p)) = p <> "은(는) 성년자이다."
renderFact (HasGuardian (PersonId p) (PersonId g)) = p <> "의 법정대리인은 " <> g <> "이다."
renderFact (HasConsent (PersonId g) (ActId a)) = g <> "이(가) " <> a <> "에 대하여 동의하였다."
renderFact (PerformsAct (PersonId p) (ActId a)) = p <> "이(가) " <> a <> "을(를) 행하였다."
renderFact (Custom t) = t
