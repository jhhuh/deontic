module Deontic.Civil.CoOwnership () where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 공유물의 처분 — Co-Ownership Disposition (§264)
--
-- This demonstrates universal quantification:
-- "공유자 전원의 동의" = ∀ owner ∈ owners, owner ∈ consented
--
-- No new framework feature needed — the open Facts type family
-- carries structured data, and the instance body uses standard
-- Haskell (all, Set.member) for the universal check.
-- ═══════════════════════════════════════════════

type instance Resolvable CoOwnershipAct = '[Base]

-- 제264조 (공유물의 처분, 변경)
-- "공유물의 처분 또는 변경은 공유자 전원의 동의가 있어야 한다."
instance Adjudicate CoOwnershipAct '[Base] where
  adjudicate _ facts
    | all (`Set.member` cofConsented facts) (cofOwners facts) =
        JBase Valid
          (ArticleRef "민법" 264 Nothing)
          "공유물의 처분 또는 변경에 관하여 공유자 전원의 동의가 있다."
    | otherwise =
        JBase Void
          (ArticleRef "민법" 264 Nothing)
          "공유자 전원의 동의가 없으므로 공유물의 처분 또는 변경은 무효이다."
