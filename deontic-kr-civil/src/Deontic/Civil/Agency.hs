module Deontic.Civil.Agency () where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Layer
import Deontic.Core.Adjudicate
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 유권대리 — Authorized Agency (§114, §118)
-- ═══════════════════════════════════════════════

type instance Resolvable AuthAgencyAct = '[Proviso, Base]

-- 제114조 (대리행위의 효력)
-- "대리인이 그 권한내에서 본인을 위한 것임을 표시한 의사표시는
--  직접 본인에게 대하여 효력이 생긴다."
instance Adjudicate AuthAgencyAct '[Base] where
  adjudicate _ _ =
    JBase Valid
      (ArticleRef "민법" 114 (Just 1))
      "대리인이 그 권한내에서 본인을 위한 것임을 표시한 의사표시는 직접 본인에게 대하여 효력이 생긴다."

-- 제118조 (자기계약, 쌍방대리)
-- "대리인은 본인의 허락이 없으면 본인을 위하여 자기와 법률행위를 하거나
--  동일한 법률행위에 관하여 당사자쌍방의 대리인이 되지 못한다."
instance Adjudicate AuthAgencyAct rest
      => Adjudicate AuthAgencyAct (Proviso ': rest) where
  adjudicate act facts
    | SelfDealing `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Voidable
                  (ArticleRef "민법" 118 Nothing)
                  "대리인은 본인의 허락이 없으면 본인을 위하여 자기와 법률행위를 하거나 동일한 법률행위에 관하여 당사자쌍방의 대리인이 되지 못한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- ═══════════════════════════════════════════════
-- 무권대리 — Unauthorized Agency (§130, §132, §125-129)
-- ═══════════════════════════════════════════════

type instance Resolvable UnauthAgencyAct = '[ApparentAuth, Ratification, Base]

-- 제130조 (무권대리)
-- "대리권없는 자가 타인의 대리인으로 한 계약은 본인이 이를 추인하지 아니하면
--  본인에 대하여 효력이 없다."
instance Adjudicate UnauthAgencyAct '[Base] where
  adjudicate _ _ =
    JBase Pending
      (ArticleRef "민법" 130 Nothing)
      "대리권없는 자가 타인의 대리인으로 한 계약은 본인이 이를 추인하지 아니하면 본인에 대하여 효력이 없다."

-- 제130조, 제132조 (추인)
-- "추인은 다른 의사표시가 없는 때에는 계약시에 소급하여 그 효력이 생긴다."
instance Adjudicate UnauthAgencyAct rest
      => Adjudicate UnauthAgencyAct (Ratification ': rest) where
  adjudicate act facts
    | Ratified `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 132 Nothing)
                  "추인은 다른 의사표시가 없는 때에는 계약시에 소급하여 그 효력이 생긴다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- 제125조, 제126조, 제129조 (표현대리)
instance Adjudicate UnauthAgencyAct rest
      => Adjudicate UnauthAgencyAct (ApparentAuth ': rest) where
  adjudicate act facts
    -- 제125조: 대리권수여의 표시에 의한 표현대리
    | IndicatedAuthority `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 125 Nothing)
                  "제삼자에 대하여 타인에게 대리권을 수여함을 표시한 자는 그 대리권의 범위내에서 행하여진 사항에 관하여 책임이 있다."
    -- 제126조: 권한을 넘은 표현대리
    | ExceededScope `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 126 Nothing)
                  "대리인이 그 권한외의 법률행위를 한 경우에 제삼자가 그 권한이 있다고 믿을 만한 정당한 이유가 있는 때에는 본인은 그 행위에 대하여 책임이 있다."
    -- 제129조: 대리권소멸 후의 표현대리
    | AuthorityExpired `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 129 Nothing)
                  "대리권의 소멸은 선의의 제삼자에게 대항하지 못한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
