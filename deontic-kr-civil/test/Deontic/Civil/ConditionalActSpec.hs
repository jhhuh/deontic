module Deontic.Civil.ConditionalActSpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types
import Deontic.Civil.ConditionalAct ()

spec :: Spec
spec = do
  describe "조건부/기한부 법률행위 (§147, §150-§152)" $ do
    let actId = ActId "매매계약"
        act   = ConditionalAct actId

    -- §147 정지조건
    it "§147①: 정지조건 미성취 → Pending" $ do
      let j = query act (ConditionalFacts Suspensive CondPending Nothing)
      verdict j `shouldBe` Pending

    it "§147①: 정지조건 성취 → Valid" $ do
      let j = query act (ConditionalFacts Suspensive CondFulfilled Nothing)
      verdict j `shouldBe` Valid

    -- §147 해제조건
    it "§147②: 해제조건 미성취 → Valid" $ do
      let j = query act (ConditionalFacts Resolutive CondPending Nothing)
      verdict j `shouldBe` Valid

    it "§147②: 해제조건 성취 → Void" $ do
      let j = query act (ConditionalFacts Resolutive CondFulfilled Nothing)
      verdict j `shouldBe` Void

    -- §152 시기/종기
    it "§152①: 시기 미도래 → Pending" $ do
      let j = query act (ConditionalFacts StartDate CondPending Nothing)
      verdict j `shouldBe` Pending

    it "§152①: 시기 도래 → Valid" $ do
      let j = query act (ConditionalFacts StartDate CondFulfilled Nothing)
      verdict j `shouldBe` Valid

    it "§152②: 종기 미도래 → Valid" $ do
      let j = query act (ConditionalFacts EndDate CondPending Nothing)
      verdict j `shouldBe` Valid

    it "§152②: 종기 도래 → Void" $ do
      let j = query act (ConditionalFacts EndDate CondFulfilled Nothing)
      verdict j `shouldBe` Void

    -- §151 불법조건
    it "§151①: 불법조건 → Void" $ do
      let j = query act (ConditionalFacts Suspensive CondIllegal Nothing)
      verdict j `shouldBe` Void

    -- §151 성취불가능
    it "§151③: 정지조건 성취불가능 → Void" $ do
      let j = query act (ConditionalFacts Suspensive CondImpossible Nothing)
      verdict j `shouldBe` Void

    it "§151③: 해제조건 성취불가능 → Valid (무조건)" $ do
      let j = query act (ConditionalFacts Resolutive CondImpossible Nothing)
      verdict j `shouldBe` Valid

    -- §150 반신의행위
    it "§150①: 정지조건 + 성취방해 → Valid (성취 의제)" $ do
      let j = query act (ConditionalFacts Suspensive CondPending (Just BadFaithPrevention))
      verdict j `shouldBe` Valid

    it "§150②: 해제조건 + 성취야기 → Valid (불성취 의제)" $ do
      let j = query act (ConditionalFacts Resolutive CondFulfilled (Just BadFaithCausation))
      verdict j `shouldBe` Valid
