module Deontic.Civil.Prescription () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 소멸시효 — Prescription (§162, §168, §174)
--
-- §157: 기간을 연으로 정한 때에는 역에 의하여 계산한다.
-- addGregorianYearsClip handles leap years correctly.
-- ═══════════════════════════════════════════════

type instance Resolvable PrescriptionAct = '[Interruption, Expiration]

-- 제162조 ① (채권의 소멸시효)
-- "채권은 10년간 행사하지 아니하면 소멸시효가 완성한다."
--
-- Expiration layer (base): calendar-year comparison
instance Adjudicate PrescriptionAct '[Expiration] where
  adjudicate _ facts
    | addGregorianYearsClip (toInteger (pfPeriodYears facts)) (pfClaimDate facts)
        <= pfCurrentDate facts =
        JBase Void
          (ArticleRef "민법" 162 (Just 1))
          "채권은 10년간 행사하지 아니하면 소멸시효가 완성한다."
    | otherwise =
        JBase Valid
          (ArticleRef "민법" 162 (Just 1))
          "소멸시효기간이 경과하지 아니하였다."

-- 제168조 (시효중단의 사유), 제174조 (시효중단의 효력)
-- "시효가 중단된 때에는 중단까지에 경과한 시효기간은 이를 산입하지 아니하고
--  중단사유가 종료한 때로부터 새로이 진행한다."
--
-- Interruption layer (override): if interrupted, recalculate from interruption date
instance Adjudicate PrescriptionAct rest
      => Adjudicate PrescriptionAct (Interruption ': rest) where
  adjudicate act facts
    | Just intDate <- pfInterruptedOn facts
    , addGregorianYearsClip (toInteger (pfPeriodYears facts)) intDate
        > pfCurrentDate facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 174 Nothing)
                  "시효가 중단된 때에는 중단까지에 경과한 시효기간은 이를 산입하지 아니하고 중단사유가 종료한 때로부터 새로이 진행한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
