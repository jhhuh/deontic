module Deontic.Civil.Rescission () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 취소의 제척기간 — Rescission Period (§146)
--
-- 제146조: "취소권은 추인할 수 있는 날로부터 3년 내에,
--          법률행위가 있은 날로부터 10년 내에 행사하여야 한다."
--
-- 제척기간이므로 중단·정지가 없다.
-- 3년 또는 10년 중 어느 하나라도 경과하면 취소권 소멸.
-- §157에 따라 역에 의한 계산 (addGregorianYearsClip).
-- ═══════════════════════════════════════════════

type instance Resolvable RescissionAct = '[Base]

-- 제146조 (취소권의 소멸)
instance Adjudicate RescissionAct '[Base] where
  adjudicate _ facts
    | addGregorianYearsClip 10 (rfActDate facts) <= rfCurrentDate facts =
        JBase Void
          (ArticleRef "민법" 146 Nothing)
          "법률행위가 있은 날로부터 10년이 경과하여 취소권이 소멸하였다."
    | addGregorianYearsClip 3 (rfKnowledgeDate facts) <= rfCurrentDate facts =
        JBase Void
          (ArticleRef "민법" 146 Nothing)
          "취소원인을 안 날로부터 3년이 경과하여 취소권이 소멸하였다."
    | otherwise =
        JBase Valid
          (ArticleRef "민법" 146 Nothing)
          "제척기간이 경과하지 아니하여 취소권을 행사할 수 있다."
