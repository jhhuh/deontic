module Deontic.Civil.Cancellation () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

type instance Resolvable CancellableAct = '[ConstructiveRatification, GeneralRatification, Base]

-- Base: 취소 또는 현상 유지
instance Adjudicate CancellableAct '[Base] where
  adjudicate act facts
    | caPriorVerdict act /= Voidable =
        JBase (caPriorVerdict act)
          (ArticleRef "민법" 141 Nothing)
          "취소할 수 있는 법률행위가 아니므로 취소의 대상이 되지 아니한다."
    | cnfCancelled facts =
        JBase Void
          (ArticleRef "민법" 141 Nothing)
          "취소된 법률행위는 처음부터 무효인 것으로 본다."
    | otherwise =
        JBase Voidable
          (ArticleRef "민법" 141 Nothing)
          "취소할 수 있는 법률행위로서 취소권이 행사되지 아니하였다."

-- §143-§144: 추인
instance Adjudicate CancellableAct rest
      => Adjudicate CancellableAct (GeneralRatification ': rest) where
  adjudicate act facts
    | cnfRatified facts
    , cnfCauseCeased facts || cnfRatifierIsGuardian facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev /= Valid =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 143 Nothing)
                  "취소할 수 있는 법률행위를 추인한 후에는 취소하지 못한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- §145: 법정추인
instance Adjudicate CancellableAct rest
      => Adjudicate CancellableAct (ConstructiveRatification ': rest) where
  adjudicate act facts
    | Just _ <- cnfConstructive facts
    , not (cnfObjectionReserved facts)
    , let prev = adjudicate @_ @rest act facts
    , verdict prev /= Valid =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 145 Nothing)
                  "추인할 수 있는 후에 법정추인 사유가 있으므로 추인한 것으로 본다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
