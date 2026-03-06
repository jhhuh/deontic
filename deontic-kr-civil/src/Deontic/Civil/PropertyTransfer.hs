module Deontic.Civil.PropertyTransfer () where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 물권변동 — Property Transfer (§186, §187, §188)
--
-- §186: 부동산 물권변동은 등기를 하여야 효력이 생긴다.
-- §187: 상속, 공용징수, 판결, 경매 등은 등기 없이도 효력.
-- §188: 동산 물권변동은 인도로 효력이 생긴다.
--
-- FormException layer overrides §186 for §187 cases.
-- ═══════════════════════════════════════════════

type instance Resolvable PropertyTransferAct = '[FormException, Base]

-- 제186조 (부동산물권변동의 효력) / 제188조 (동산물권양도의 효력)
instance Adjudicate PropertyTransferAct '[Base] where
  adjudicate _ facts
    | Set.member IsRealProperty facts
    , Set.member HasRegistration facts =
        JBase Valid
          (ArticleRef "민법" 186 Nothing)
          "부동산에 관한 법률행위로 인한 물권의 득실변경은 등기하여야 그 효력이 생긴다."
    | Set.member IsRealProperty facts =
        JBase Void
          (ArticleRef "민법" 186 Nothing)
          "등기를 하지 아니하여 부동산 물권변동의 효력이 없다."
    | Set.member IsMovableProperty facts
    , Set.member HasDelivery facts =
        JBase Valid
          (ArticleRef "민법" 188 (Just 1))
          "동산에 관한 물권의 양도는 그 동산을 인도하여야 효력이 생긴다."
    | Set.member IsMovableProperty facts =
        JBase Void
          (ArticleRef "민법" 188 (Just 1))
          "인도를 하지 아니하여 동산 물권변동의 효력이 없다."
    | otherwise =
        JBase Void
          (ArticleRef "민법" 186 Nothing)
          "물권변동의 대상이 특정되지 아니하였다."

-- 제187조 (등기를 요하지 아니하는 부동산물권취득)
-- "상속, 공용징수, 판결, 경매 기타 법률의 규정에 의한 부동산에 관한
--  물권의 취득은 등기를 요하지 아니한다."
instance Adjudicate PropertyTransferAct rest
      => Adjudicate PropertyTransferAct (FormException ': rest) where
  adjudicate act facts
    | Set.member IsRealProperty facts
    , any (`Set.member` facts) [ByInheritance, ByCourtOrder, ByPublicAuction, ByExpropriation] =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 187 Nothing)
                  "상속, 공용징수, 판결, 경매 기타 법률의 규정에 의한 부동산물권취득은 등기를 요하지 아니한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
