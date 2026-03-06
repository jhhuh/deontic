module Deontic.Civil.Possession () where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 점유권의 추정 — Rebuttable Presumptions (§197, §200)
--
-- This demonstrates negation/default reasoning:
-- The ABSENCE of rebuttal evidence means the
-- presumption holds (default Valid).
-- ═══════════════════════════════════════════════

type instance Resolvable PossessionAct = '[Rebuttal, Presumption]

-- 제197조 ① (점유의 태양)
-- "점유자는 소유의 의사로 선의, 평온 및 공연하게 점유한 것으로 추정한다."
-- 제200조 (점유의 추정)
-- "점유자의 점유가 소유의 의사로 하는 점유인지의 여부가 분명하지 아니한
--  때에는 소유의 의사로 점유한 것으로 추정한다."
--
-- Presumption layer: default = Valid (presumption holds)
instance Adjudicate PossessionAct '[Presumption] where
  adjudicate _ _ =
    JBase Valid
      (ArticleRef "민법" 197 (Just 1))
      "점유자는 소유의 의사로 선의, 평온 및 공연하게 점유한 것으로 추정한다."

-- Rebuttal layer: if counter-evidence present, override the presumption
instance Adjudicate PossessionAct rest
      => Adjudicate PossessionAct (Rebuttal ': rest) where
  adjudicate act facts
    -- §197 반증: 악의 점유
    | BadFaith `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Voidable
                  (ArticleRef "민법" 197 (Just 1))
                  "반증: 점유자가 악의로 점유한 것으로 인정됨."
    -- §197 반증: 강폭 점유
    | ViolentPossession `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Voidable
                  (ArticleRef "민법" 197 (Just 1))
                  "반증: 점유가 평온하지 아니한 것으로 인정됨."
    -- §197 반증: 은비 점유
    | ClandestinePossession `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Voidable
                  (ArticleRef "민법" 197 (Just 1))
                  "반증: 점유가 공연하지 아니한 것으로 인정됨."
    -- §200 반증: 타주점유
    | NoOwnershipIntent `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Voidable
                  (ArticleRef "민법" 200 Nothing)
                  "반증: 소유의 의사가 없는 타주점유로 인정됨."
    -- No rebuttal evidence → presumption holds (delegate)
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
