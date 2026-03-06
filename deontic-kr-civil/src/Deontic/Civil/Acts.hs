module Deontic.Civil.Acts () where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Layer
import Deontic.Core.Adjudicate
import Deontic.Civil.Types (JuristicAct(..))

type instance Resolvable JuristicAct = '[SpecialRule, Proviso, Base]

-- 제107조(비진의 의사표시) — Base layer
instance Adjudicate JuristicAct '[Base] where
  adjudicate _ facts
    | Custom "hidden-intention" `Set.member` facts =
        JBase Valid
          (ArticleRef "민법" 107 (Just 1))
          "의사표시는 표의자가 진의아님을 알고 한 것이라도 그 효력에 영향을 미치지 아니한다."
    | otherwise =
        JBase Valid
          (ArticleRef "민법" 0 Nothing)
          "법률행위의 일반적 유효 추정"

-- 제107조 ② — Proviso layer
instance Adjudicate JuristicAct '[Base]
      => Adjudicate JuristicAct '[Proviso, Base] where
  adjudicate act facts
    | Custom "hidden-intention" `Set.member` facts
      && Custom "counterparty-knew" `Set.member` facts =
        JOverride (adjudicate @_ @'[Base] act facts)
                  Void
                  (ArticleRef "민법" 107 (Just 2))
                  "상대방이 표의자의 진의아님을 알았거나 알 수 있었을 경우에는 무효로 한다."
    | otherwise =
        JDelegate (adjudicate @_ @'[Base] act facts)

-- 제103조, 제104조 — SpecialRule layer (overrides everything)
instance Adjudicate JuristicAct '[Proviso, Base]
      => Adjudicate JuristicAct '[SpecialRule, Proviso, Base] where
  adjudicate act facts
    | Custom "contra-bonos-mores" `Set.member` facts =
        JOverride (adjudicate @_ @'[Proviso, Base] act facts)
                  Void
                  (ArticleRef "민법" 103 Nothing)
                  "선량한 풍속 기타 사회질서에 위반한 사항을 내용으로 하는 법률행위는 무효로 한다."
    | Custom "exploitative-act" `Set.member` facts =
        JOverride (adjudicate @_ @'[Proviso, Base] act facts)
                  Void
                  (ArticleRef "민법" 104 Nothing)
                  "당사자의 궁박, 경솔 또는 무경험으로 인하여 현저하게 공정을 잃은 법률행위는 무효로 한다."
    | otherwise =
        JDelegate (adjudicate @_ @'[Proviso, Base] act facts)
