module Deontic.Civil.RescissionSpec (spec) where

import Test.Hspec
import Data.Time.Calendar (fromGregorian)
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Rescission ()

spec :: Spec
spec = do
  describe "취소의 제척기간 (§146)" $ do
    let actor = PersonId "갑"
        actId = ActId "매매계약"
        act   = RescissionAct actor actId
        -- 법률행위일: 2015-06-01, 취소원인을 안 날: 2020-03-01
        actDate  = fromGregorian 2015 6 1
        knowDate = fromGregorian 2020 3 1

    it "§146: 3년 미경과, 10년 미경과 → Valid (취소권 존속)" $ do
      let j = query act (RescissionFacts knowDate actDate (fromGregorian 2021 1 1))
      verdict j `shouldBe` Valid

    it "§146: 3년 경과 → Void (취소권 소멸)" $ do
      -- 2020-03-01 + 3년 = 2023-03-01
      let j = query act (RescissionFacts knowDate actDate (fromGregorian 2024 1 1))
      verdict j `shouldBe` Void

    it "§146: 10년 경과 → Void (절대적 제척기간)" $ do
      -- 2015-06-01 + 10년 = 2025-06-01
      let j = query act (RescissionFacts knowDate actDate (fromGregorian 2026 1 1))
      verdict j `shouldBe` Void

    it "§146: 10년 경과 시 근거조문은 §146" $ do
      let j = query act (RescissionFacts knowDate actDate (fromGregorian 2026 1 1))
          steps = judgmentSteps j
      articleNumber (stepArticle (last steps)) `shouldBe` 146

    it "§146: 3년 만료 전날 → Valid" $ do
      -- 2020-03-01 + 3년 = 2023-03-01; 전날 = 2023-02-28
      let j = query act (RescissionFacts knowDate actDate (fromGregorian 2023 2 28))
      verdict j `shouldBe` Valid

    it "§146: 정확히 3년 만료일 → Void" $ do
      -- 2020-03-01 + 3년 = 2023-03-01
      let j = query act (RescissionFacts knowDate actDate (fromGregorian 2023 3 1))
      verdict j `shouldBe` Void

    it "§146: 10년 미경과지만 3년 경과 → Void (3년 제척기간)" $ do
      -- 행위 후 8년, 인지 후 4년
      let j = query act (RescissionFacts knowDate actDate (fromGregorian 2024 6 1))
      verdict j `shouldBe` Void

    it "§146: 10년 경과했지만 3년 미경과 → Void (10년 절대적 제척기간)" $ do
      -- 행위 후 11년, 인지 후 1년 (매우 늦게 인지)
      let lateKnow = fromGregorian 2025 12 1
      let j = query act (RescissionFacts lateKnow actDate (fromGregorian 2026 6 1))
      verdict j `shouldBe` Void
