module Deontic.Civil.SaleWarranty () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 하자담보책임 — Sale Warranty (§580, §581, §582)
--
-- §580①: 매매의 목적물에 하자가 있는 때에는 매수인은
--         계약의 해제 또는 손해배상을 청구할 수 있다.
-- §580②: 그러나 매수인이 하자 있는 것을 알았거나 과실로 인하여
--         이를 알지 못한 때에는 그러하지 아니하다.
-- §581: 중대한 하자 → 계약해제 가능.
-- §582: 매수인이 사실을 안 날로부터 6월 내에 행사.
--
-- BuyerKnowledge layer: §580② 매수인 악의·과실 → Valid (면책)
-- ═══════════════════════════════════════════════

type instance Resolvable WarrantyAct = '[BuyerKnowledge, Base]

-- 제580조 제1항 (매도인의 하자담보책임)
instance Adjudicate WarrantyAct '[Base] where
  adjudicate _ facts
    | not (wfDefectExists facts) =
        JBase Valid
          (ArticleRef "민법" 580 (Just 1))
          "매매 목적물에 하자가 없으므로 하자담보책임이 없다."
    | not (wfNotifiedInTime facts) =
        JBase Valid
          (ArticleRef "민법" 582 Nothing)
          "매수인이 사실을 안 날로부터 6월 내에 행사하지 아니하여 하자담보책임을 물을 수 없다."
    | wfSignificant facts =
        JBase Void
          (ArticleRef "민법" 580 (Just 1))
          "매매 목적물에 중대한 하자가 있어 계약의 해제 및 손해배상을 청구할 수 있다."
    | otherwise =
        JBase Voidable
          (ArticleRef "민법" 580 (Just 1))
          "매매 목적물에 하자가 있어 손해배상을 청구할 수 있다."

-- 제580조 제2항 (매수인의 악의·과실)
instance Adjudicate WarrantyAct rest
      => Adjudicate WarrantyAct (BuyerKnowledge ': rest) where
  adjudicate act facts
    | wfBuyerKnew facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev /= Valid =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 580 (Just 2))
                  "매수인이 하자 있는 것을 알았거나 과실로 인하여 이를 알지 못한 때에는 하자담보책임을 물을 수 없다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
