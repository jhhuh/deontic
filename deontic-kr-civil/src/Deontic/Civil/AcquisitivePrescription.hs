module Deontic.Civil.AcquisitivePrescription () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 취득시효 — Acquisitive Prescription (§245, §246)
--
-- §245①: 20년간 소유의 의사로 평온, 공연하게 부동산을
--         점유하는 자는 등기함으로써 그 소유권을 취득한다.
-- §245②: 부동산의 소유자로 등기한 자가 10년간 소유의 의사로
--         평온, 공연하게 선의이며 과실 없이 그 부동산을 점유한
--         때에는 소유권을 취득한다.
--
-- §157에 따라 역에 의한 계산 (addGregorianYearsClip).
-- ShortPrescription layer overrides for §245② (10-year).
-- ═══════════════════════════════════════════════

type instance Resolvable AcqPrescriptionAct = '[ShortPrescription, Base]

-- 제245조 제1항 (점유로 인한 부동산소유권의 취득기간)
instance Adjudicate AcqPrescriptionAct '[Base] where
  adjudicate _ facts
    | apfSelfPossession facts
    , apfPeaceful facts
    , apfPublic facts
    , addGregorianYearsClip 20 (apfStartDate facts) <= apfCurrentDate facts =
        JBase Valid
          (ArticleRef "민법" 245 (Just 1))
          "20년간 소유의 의사로 평온, 공연하게 부동산을 점유하여 취득시효가 완성되었다."
    | otherwise =
        JBase Void
          (ArticleRef "민법" 245 (Just 1))
          "취득시효의 요건이 충족되지 아니하였다."

-- 제245조 제2항 (단기 취득시효)
instance Adjudicate AcqPrescriptionAct rest
      => Adjudicate AcqPrescriptionAct (ShortPrescription ': rest) where
  adjudicate act facts
    | apfSelfPossession facts
    , apfPeaceful facts
    , apfPublic facts
    , apfGoodFaith facts
    , apfNoNegligence facts
    , addGregorianYearsClip 10 (apfStartDate facts) <= apfCurrentDate facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 245 (Just 2))
                  "10년간 소유의 의사로 평온, 공연하게 선의이며 과실 없이 부동산을 점유하여 단기 취득시효가 완성되었다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
