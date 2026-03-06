module Deontic.Civil.Tort () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 불법행위 — Tort Liability (§750, §763→§396)
--
-- §750 requires ALL four elements:
--   고의/과실 + 위법성 + 손해 + 인과관계
-- Missing any element → no liability (Valid for defendant).
--
-- §763→§396 과실상계: if victim contributed, liability
-- is reduced (modeled as Voidable = partially defeasible).
-- ═══════════════════════════════════════════════

type instance Resolvable TortAct = '[ContributoryNeg, Base]

-- 제750조 (불법행위의 내용)
-- "고의 또는 과실로 인한 위법행위로 타인에게 손해를 가한 자는
--  그 손해를 배상할 책임이 있다."
instance Adjudicate TortAct '[Base] where
  adjudicate _ facts
    | tfFault facts && tfUnlawful facts
      && tfDamage facts && tfCausation facts =
        JBase Void
          (ArticleRef "민법" 750 Nothing)
          "고의 또는 과실로 인한 위법행위로 타인에게 손해를 가한 자는 그 손해를 배상할 책임이 있다."
    | otherwise =
        JBase Valid
          (ArticleRef "민법" 750 Nothing)
          "불법행위의 요건이 충족되지 아니하여 손해배상 책임이 없다."

-- 제763조 → 제396조 (과실상계)
-- "채무불이행에 관하여 채권자에게 과실이 있는 때에는 법원은
--  손해배상의 책임 및 그 금액을 정함에 이를 참작하여야 한다."
instance Adjudicate TortAct rest
      => Adjudicate TortAct (ContributoryNeg ': rest) where
  adjudicate act facts
    | tfVictimNeg facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =  -- 과실상계는 책임이 성립한 경우에만 적용
        JOverride prev
                  Voidable
                  (ArticleRef "민법" 396 Nothing)
                  "피해자에게도 과실이 있으므로 과실상계에 의하여 손해배상 책임이 감경된다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
