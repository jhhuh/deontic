{-# LANGUAGE LambdaCase #-}
module Deontic.Civil.Persons () where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Layer
import Deontic.Core.Adjudicate
import Deontic.Civil.Types (MinorAct(..))

type instance Resolvable MinorAct = '[Proviso, Base]

-- 제5조(미성년자의 법률행위) ① 본문
-- "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다."
instance Adjudicate MinorAct '[Base] where
  adjudicate (MinorAct _actor actId) facts
    | hasConsent actId facts =
        JBase Valid
          (ArticleRef "민법" 5 (Just 1))
          "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다."
    | otherwise =
        JBase Voidable
          (ArticleRef "민법" 5 (Just 1))
          "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다."

-- 제5조 ① 단서
-- "권리만을 얻거나 의무만을 면하는 법률행위는 그러하지 아니하다."
instance Adjudicate MinorAct rest
      => Adjudicate MinorAct (Proviso ': rest) where
  adjudicate act facts
    | Custom "merely-acquires-right" `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 5 (Just 1))
                  "권리만을 얻거나 의무만을 면하는 법률행위는 그러하지 아니하다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

hasConsent :: ActId -> Facts -> Bool
hasConsent actId facts =
  any (\case HasConsent _ a -> a == actId; _ -> False) (Set.toList facts)
