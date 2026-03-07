module Deontic.Civil.ConditionalAct () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

type instance Resolvable ConditionalAct = '[BadFaithCondition, IllegalCondition, Base]

-- §147/§152: 조건/기한의 기본 효과
instance Adjudicate ConditionalAct '[Base] where
  adjudicate _ facts = case (condType facts, condState facts) of
    (Suspensive, CondPending)   -> JBase Pending (ArticleRef "민법" 147 (Just 1))
      "정지조건이 성취되지 아니하여 효력이 발생하지 아니한다."
    (Suspensive, CondFulfilled) -> JBase Valid (ArticleRef "민법" 147 (Just 1))
      "정지조건이 성취하여 효력이 생긴다."
    (Resolutive, CondPending)   -> JBase Valid (ArticleRef "민법" 147 (Just 2))
      "해제조건이 성취되지 아니하여 효력이 존속한다."
    (Resolutive, CondFulfilled) -> JBase Void (ArticleRef "민법" 147 (Just 2))
      "해제조건이 성취하여 효력을 잃는다."
    (StartDate,  CondPending)   -> JBase Pending (ArticleRef "민법" 152 (Just 1))
      "시기가 도래하지 아니하여 효력이 발생하지 아니한다."
    (StartDate,  CondFulfilled) -> JBase Valid (ArticleRef "민법" 152 (Just 1))
      "시기가 도래하여 효력이 생긴다."
    (EndDate,    CondPending)   -> JBase Valid (ArticleRef "민법" 152 (Just 2))
      "종기가 도래하지 아니하여 효력이 존속한다."
    (EndDate,    CondFulfilled) -> JBase Void (ArticleRef "민법" 152 (Just 2))
      "종기가 도래하여 효력을 잃는다."
    -- impossible/illegal handled by upper layers; Base falls back to Pending
    (_, CondImpossible) -> JBase Pending (ArticleRef "민법" 147 (Just 1))
      "조건의 성취가 불가능하다."
    (_, CondIllegal)    -> JBase Pending (ArticleRef "민법" 147 (Just 1))
      "불법조건이다."

-- §151: 불법조건, 기성조건, 불능조건
instance Adjudicate ConditionalAct rest
      => Adjudicate ConditionalAct (IllegalCondition ': rest) where
  adjudicate act facts = case condState facts of
    CondIllegal ->
      JOverride (adjudicate @_ @rest act facts)
                Void
                (ArticleRef "민법" 151 (Just 1))
                "조건이 선량한 풍속 기타 사회질서에 위반한 것인 때에는 그 법률행위는 무효로 한다."
    CondImpossible -> case condType facts of
      Suspensive ->
        JOverride (adjudicate @_ @rest act facts)
                  Void
                  (ArticleRef "민법" 151 (Just 3))
                  "조건이 성취할 수 없는 것인 경우에 정지조건이면 그 법률행위는 무효로 한다."
      StartDate ->
        JOverride (adjudicate @_ @rest act facts)
                  Void
                  (ArticleRef "민법" 151 (Just 3))
                  "시기가 도래할 수 없는 것인 경우 그 법률행위는 무효로 한다."
      Resolutive ->
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 151 (Just 3))
                  "조건이 성취할 수 없는 것인 경우에 해제조건이면 조건 없는 법률행위로 한다."
      EndDate ->
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 151 (Just 3))
                  "종기가 도래할 수 없는 것인 경우 기한 없는 법률행위로 한다."
    _ -> JDelegate (adjudicate @_ @rest act facts)

-- §150: 반신의행위
instance Adjudicate ConditionalAct rest
      => Adjudicate ConditionalAct (BadFaithCondition ': rest) where
  adjudicate act facts = case condBadFaith facts of
    Just BadFaithPrevention ->
      -- 성취 의제: re-evaluate as if condition fulfilled
      let deemedFacts = facts { condState = CondFulfilled, condBadFaith = Nothing }
          deemedResult = query act deemedFacts
      in JOverride (adjudicate @_ @rest act facts)
                   (verdict deemedResult)
                   (ArticleRef "민법" 150 (Just 1))
                   "조건의 성취로 인하여 불이익을 받을 당사자가 신의성실에 반하여 조건의 성취를 방해한 때에는 상대방은 그 조건이 성취한 것으로 주장할 수 있다."
    Just BadFaithCausation ->
      -- 불성취 의제: re-evaluate as if condition pending
      let deemedFacts = facts { condState = CondPending, condBadFaith = Nothing }
          deemedResult = query act deemedFacts
      in JOverride (adjudicate @_ @rest act facts)
                   (verdict deemedResult)
                   (ArticleRef "민법" 150 (Just 2))
                   "조건의 성취로 인하여 이익을 받을 당사자가 신의성실에 반하여 조건을 성취시킨 때에는 상대방은 그 조건이 성취하지 아니한 것으로 주장할 수 있다."
    Nothing ->
      JDelegate (adjudicate @_ @rest act facts)
