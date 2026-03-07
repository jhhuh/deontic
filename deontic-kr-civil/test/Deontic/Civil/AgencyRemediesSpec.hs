module Deontic.Civil.AgencyRemediesSpec (spec) where

import Test.Hspec
import Data.Set qualified as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types
import Deontic.Civil.AgencyRemedies ()

spec :: Spec
spec = do
  describe "상대방의 철회권 (§134)" $ do
    let principal    = PersonId "갑"
        counterparty = PersonId "을"
        actId        = ActId "매매계약"
        act          = AgencyWithdrawalAct principal counterparty actId

    it "§134 본문: 추인 전 상대방은 철회 가능 → Valid" $ do
      let j = query act Set.empty
      verdict j `shouldBe` Valid

    it "§134 단서: 상대방이 무권대리를 안 때 → Void (철회불가)" $ do
      let j = query act (Set.singleton CounterpartyKnewNoAuthority)
      verdict j `shouldBe` Void

  describe "무권대리인의 책임 (§135)" $ do
    let agent        = PersonId "병"
        counterparty = PersonId "을"
        actId        = ActId "매매계약"
        act          = AgentLiabilityAct agent counterparty actId

    it "§135①: 무권대리인은 이행 또는 손해배상 책임 → Void" $ do
      let j = query act Set.empty
      verdict j `shouldBe` Void

    it "§135②: 상대방이 무권대리를 안 때 → Valid (면책)" $ do
      let j = query act (Set.singleton CounterpartyKnewNoAuthority)
      verdict j `shouldBe` Valid

    it "§135②: 상대방이 알 수 있었을 때 → Valid (면책)" $ do
      let j = query act (Set.singleton CounterpartyCouldHaveKnown)
      verdict j `shouldBe` Valid

    it "§135②: 대리인이 제한능력자 → Valid (면책)" $ do
      let j = query act (Set.singleton AgentIsLimitedCapacity)
      verdict j `shouldBe` Valid
