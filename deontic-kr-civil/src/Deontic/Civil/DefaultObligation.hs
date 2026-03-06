module Deontic.Civil.DefaultObligation () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 채무불이행 — Default/Breach of Obligation (§387-§390)
--
-- §387: 이행기가 도래하면 이행지체의 책임이 있다.
-- §388: 이행불능에는 전보배상의 책임이 있다.
-- §390: 채무자의 고의나 과실 없으면 면책.
--        그러나 채권자에게도 과실이 있으면 감경.
--
-- CreditorDefense layer: §390 채권자 과실 → Voidable
-- ═══════════════════════════════════════════════

type instance Resolvable DefaultAct = '[CreditorDefense, Base]

-- 제387조-제389조 (이행지체·이행불능)
instance Adjudicate DefaultAct '[Base] where
  adjudicate _ facts
    | not (dfPerformanceDue facts) =
        JBase Valid
          (ArticleRef "민법" 387 (Just 1))
          "이행기가 도래하지 아니하여 채무불이행이 아니다."
    | not (dfNonPerformance facts) =
        JBase Valid
          (ArticleRef "민법" 387 (Just 1))
          "채무를 이행하였으므로 채무불이행이 아니다."
    | not (dfDebtorFault facts) =
        JBase Valid
          (ArticleRef "민법" 390 Nothing)
          "채무자의 고의나 과실 없는 사유로 이행하지 아니한 때에는 손해배상의 책임이 없다."
    | dfImpossible facts =
        JBase Void
          (ArticleRef "민법" 390 Nothing)
          "채무자의 귀책사유로 이행이 불능하게 되어 전보배상의 책임이 있다."
    | otherwise =
        JBase Void
          (ArticleRef "민법" 387 (Just 1))
          "이행기가 도래하였으나 이행하지 아니하여 이행지체의 책임이 있다."

-- 제390조 단서 (채권자 과실에 의한 감경)
instance Adjudicate DefaultAct rest
      => Adjudicate DefaultAct (CreditorDefense ': rest) where
  adjudicate act facts
    | dfCreditorFault facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =
        JOverride prev
                  Voidable
                  (ArticleRef "민법" 390 Nothing)
                  "채권자에게도 과실이 있으므로 손해배상의 책임이 감경된다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
