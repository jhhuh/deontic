module Deontic.Civil.Lease () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 임대차 — Lease (§618, §623, §639, §640)
--
-- §618: 임대차는 당사자 일방이 상대방에게 목적물을
--        사용·수익하게 할 것을 약정하고 상대방이 이에
--        대하여 차임을 지급할 것을 약정함으로써 성립.
-- §623: 임대인은 목적물을 사용·수익에 필요한 상태로 유지.
-- §639: 묵시적 갱신 — 기간 만료 후 계속 사용 + 이의 없음.
-- §640: 차임 2기 연체 → 해지 가능.
--
-- RenewalRight layer: §639 묵시적 갱신 overrides expiration.
-- ═══════════════════════════════════════════════

type instance Resolvable LeaseAct = '[RenewalRight, Base]

-- 제618조 (임대차의 의의) + §640 (차임연체와 해지)
instance Adjudicate LeaseAct '[Base] where
  adjudicate _ facts
    | not (lfValidContract facts) =
        JBase Void
          (ArticleRef "민법" 618 Nothing)
          "유효한 임대차계약이 성립하지 아니하였다."
    | lfTwoRentsLate facts =
        JBase Void
          (ArticleRef "민법" 640 Nothing)
          "임차인의 차임연체액이 2기의 차임액에 달하여 임대인은 계약을 해지할 수 있다."
    | lfPeriodExpired facts =
        JBase Void
          (ArticleRef "민법" 618 Nothing)
          "임대차 기간이 만료하여 계약이 종료하였다."
    | otherwise =
        JBase Valid
          (ArticleRef "민법" 618 Nothing)
          "유효한 임대차계약이 존속하고 있다."

-- 제639조 (묵시적 갱신)
-- "임대차기간이 만료한 후 임차인이 임차물의 사용 또는 수익을
--  계속하는 경우에 임대인이 상당한 기간내에 이의를 하지 아니한
--  때에는 전임대차와 동일한 조건으로 다시 임대차한 것으로 본다."
instance Adjudicate LeaseAct rest
      => Adjudicate LeaseAct (RenewalRight ': rest) where
  adjudicate act facts
    | lfPeriodExpired facts
    , lfContinuedUse facts
    , lfNoObjection facts
    , not (lfTwoRentsLate facts) =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 639 (Just 1))
                  "임대차기간 만료 후 임차인이 사용을 계속하고 임대인이 이의를 하지 아니하여 묵시적으로 갱신된 것으로 본다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
