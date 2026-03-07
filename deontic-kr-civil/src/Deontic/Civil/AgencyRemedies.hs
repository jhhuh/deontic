module Deontic.Civil.AgencyRemedies () where

import Data.Set qualified as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Proviso, Resolvable)
import Deontic.Civil.Types

type instance Resolvable AgencyWithdrawalAct = '[CounterpartyKnowledge, Base]

instance Adjudicate AgencyWithdrawalAct '[Base] where
  adjudicate _ _ =
    JBase Valid
      (ArticleRef "민법" 134 Nothing)
      "본인의 추인이 있을 때까지 상대방은 본인이나 그 대리인에 대하여 철회할 수 있다."

instance Adjudicate AgencyWithdrawalAct rest
      => Adjudicate AgencyWithdrawalAct (CounterpartyKnowledge ': rest) where
  adjudicate act facts
    | Set.member CounterpartyKnewNoAuthority facts =
        JOverride (adjudicate @_ @rest act facts)
                  Void
                  (ArticleRef "민법" 134 Nothing)
                  "계약 당시에 상대방이 대리권 없음을 안 때에는 철회하지 못한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

type instance Resolvable AgentLiabilityAct = '[Proviso, Base]

instance Adjudicate AgentLiabilityAct '[Base] where
  adjudicate _ _ =
    JBase Void
      (ArticleRef "민법" 135 (Just 1))
      "대리권을 증명하지 못하고 본인의 추인을 받지 못한 자는 상대방의 선택에 따라 이행 또는 손해배상의 책임이 있다."

instance Adjudicate AgentLiabilityAct rest
      => Adjudicate AgentLiabilityAct (Proviso ': rest) where
  adjudicate act facts
    | Set.member CounterpartyKnewNoAuthority facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 135 (Just 2))
                  "상대방이 대리권 없음을 안 때에는 무권대리인의 책임이 없다."
    | Set.member CounterpartyCouldHaveKnown facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 135 (Just 2))
                  "상대방이 대리권 없음을 알 수 있었을 때에는 무권대리인의 책임이 없다."
    | Set.member AgentIsLimitedCapacity facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 135 (Just 2))
                  "대리인이 제한능력자인 때에는 무권대리인의 책임이 없다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
