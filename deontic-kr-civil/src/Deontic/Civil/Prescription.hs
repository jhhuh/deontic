module Deontic.Civil.Prescription () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 소멸시효 — Prescription (§162, §168, §174)
--
-- This demonstrates temporal reasoning:
-- Facts act = PrescriptionFacts (a record with numeric fields),
-- not Set CivilFact. The open Facts type family allows each
-- act type to define its own fact structure.
-- ═══════════════════════════════════════════════

type instance Resolvable PrescriptionAct = '[Interruption, Expiration]

-- 제162조 ① (채권의 소멸시효)
-- "채권은 10년간 행사하지 아니하면 소멸시효가 완성한다."
--
-- Expiration layer (base): raw elapsed time vs statutory period
instance Adjudicate PrescriptionAct '[Expiration] where
  adjudicate _ facts
    | pfElapsedDays facts >= pfPeriodDays facts =
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
-- Interruption layer (override): if interrupted, recalculate from interruption point
instance Adjudicate PrescriptionAct rest
      => Adjudicate PrescriptionAct (Interruption ': rest) where
  adjudicate act facts
    | Just intAfter <- pfInterruptedAfter facts
    , let daysSinceInterruption = pfElapsedDays facts - intAfter
    , daysSinceInterruption < pfPeriodDays facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 174 Nothing)
                  "시효가 중단된 때에는 중단까지에 경과한 시효기간은 이를 산입하지 아니하고 중단사유가 종료한 때로부터 새로이 진행한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
