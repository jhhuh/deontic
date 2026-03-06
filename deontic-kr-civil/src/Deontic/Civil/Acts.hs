module Deontic.Civil.Acts () where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Layer
import Deontic.Core.Adjudicate
import Deontic.Civil.Types (JuristicAct(..), ShamAct(..), MistakeAct(..), FraudAct(..), CivilFact(..))

type instance Resolvable JuristicAct = '[SpecialRule, Proviso, Base]

-- 제107조(비진의 의사표시) — Base layer
instance Adjudicate JuristicAct '[Base] where
  adjudicate _ facts
    | HiddenIntention `Set.member` facts =
        JBase Valid
          (ArticleRef "민법" 107 (Just 1))
          "의사표시는 표의자가 진의아님을 알고 한 것이라도 그 효력에 영향을 미치지 아니한다."
    | otherwise =
        JBase Valid
          (ArticleRef "민법" 0 Nothing)
          "법률행위의 일반적 유효 추정"

-- 제107조 ② — Proviso layer
instance Adjudicate JuristicAct rest
      => Adjudicate JuristicAct (Proviso ': rest) where
  adjudicate act facts
    | HiddenIntention `Set.member` facts
      && CounterpartyKnew `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Void
                  (ArticleRef "민법" 107 (Just 2))
                  "상대방이 표의자의 진의아님을 알았거나 알 수 있었을 경우에는 무효로 한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- 제103조, 제104조 — SpecialRule layer (overrides everything)
instance Adjudicate JuristicAct rest
      => Adjudicate JuristicAct (SpecialRule ': rest) where
  adjudicate act facts
    | ContraBonorsMores `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Void
                  (ArticleRef "민법" 103 Nothing)
                  "선량한 풍속 기타 사회질서에 위반한 사항을 내용으로 하는 법률행위는 무효로 한다."
    | ExploitativeAct `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Void
                  (ArticleRef "민법" 104 Nothing)
                  "당사자의 궁박, 경솔 또는 무경험으로 인하여 현저하게 공정을 잃은 법률행위는 무효로 한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- ═══════════════════════════════════════════════
-- 제108조 — 통정허위표시
-- ═══════════════════════════════════════════════

type instance Resolvable ShamAct = '[Proviso, Base]

-- 제108조 ① "상대방과 통정한 허위의 의사표시는 무효로 한다."
instance Adjudicate ShamAct '[Base] where
  adjudicate _ _ =
    JBase Void
      (ArticleRef "민법" 108 (Just 1))
      "상대방과 통정한 허위의 의사표시는 무효로 한다."

-- 제108조 ② "전항의 의사표시의 무효는 선의의 제삼자에게 대항하지 못한다."
instance Adjudicate ShamAct rest
      => Adjudicate ShamAct (Proviso ': rest) where
  adjudicate act facts
    | BonaFideThirdParty `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 108 (Just 2))
                  "전항의 의사표시의 무효는 선의의 제삼자에게 대항하지 못한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- ═══════════════════════════════════════════════
-- 제109조 — 착오로 인한 의사표시
-- ═══════════════════════════════════════════════

type instance Resolvable MistakeAct = '[Proviso, Base]

-- 제109조 ① 본문
-- "의사표시는 법률행위의 내용의 중요부분에 착오가 있는 때에는 취소할 수 있다."
instance Adjudicate MistakeAct '[Base] where
  adjudicate _ _ =
    JBase Voidable
      (ArticleRef "민법" 109 (Just 1))
      "의사표시는 법률행위의 내용의 중요부분에 착오가 있는 때에는 취소할 수 있다."

-- 제109조 ① 단서
-- "그러나 그 착오가 표의자의 중대한 과실로 인한 때에는 취소하지 못한다."
instance Adjudicate MistakeAct rest
      => Adjudicate MistakeAct (Proviso ': rest) where
  adjudicate act facts
    | GrossNegligence `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 109 (Just 1))
                  "그러나 그 착오가 표의자의 중대한 과실로 인한 때에는 취소하지 못한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- ═══════════════════════════════════════════════
-- 제110조 — 사기, 강박에 의한 의사표시
-- ═══════════════════════════════════════════════

type instance Resolvable FraudAct = '[Proviso, Base]

-- 제110조 ① "사기나 강박에 의한 의사표시는 취소할 수 있다."
instance Adjudicate FraudAct '[Base] where
  adjudicate _ _ =
    JBase Voidable
      (ArticleRef "민법" 110 (Just 1))
      "사기나 강박에 의한 의사표시는 취소할 수 있다."

-- 제110조 ②
-- "상대방있는 의사표시에 관하여 제삼자가 사기를 행한 경우에는
--  상대방이 그 사실을 알았거나 알 수 있었을 경우에 한하여
--  그 의사표시를 취소할 수 있다."
instance Adjudicate FraudAct rest
      => Adjudicate FraudAct (Proviso ': rest) where
  adjudicate act facts
    | ThirdPartyFraud `Set.member` facts
      && not (CounterpartyKnewFraud `Set.member` facts) =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 110 (Just 2))
                  "상대방있는 의사표시에 관하여 제삼자가 사기를 행한 경우에는 상대방이 그 사실을 알았거나 알 수 있었을 경우에 한하여 그 의사표시를 취소할 수 있다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
