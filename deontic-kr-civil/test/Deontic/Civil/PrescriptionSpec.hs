module Deontic.Civil.PrescriptionSpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Prescription ()

-- Helper: 10-year prescription in days
tenYears :: Int
tenYears = 3650

spec :: Spec
spec = do
  describe "소멸시효 — Prescription (§162, §168, §174)" $ do
    let creditor = PersonId "채권자"
        claimId  = ActId "대여금채권"
        act      = PrescriptionAct creditor claimId

    it "시효기간 내 → Valid (소멸시효 미완성)" $ do
      let facts = PrescriptionFacts { pfElapsedDays = 1825  -- 5 years
                                    , pfPeriodDays = tenYears
                                    , pfInterruptedAfter = Nothing }
      verdict (query act facts) `shouldBe` Valid

    it "시효기간 경과 → Void (소멸시효 완성, §162①)" $ do
      let facts = PrescriptionFacts { pfElapsedDays = 4000  -- ~11 years
                                    , pfPeriodDays = tenYears
                                    , pfInterruptedAfter = Nothing }
      verdict (query act facts) `shouldBe` Void

    it "시효기간 경과 but 중단 → Valid (§174 시효중단)" $ do
      -- 11 years total, but interrupted at year 8 → 3 years since interruption < 10
      let facts = PrescriptionFacts { pfElapsedDays = 4015
                                    , pfPeriodDays = tenYears
                                    , pfInterruptedAfter = Just 2920 }  -- interrupted at ~8 years
      verdict (query act facts) `shouldBe` Valid

    it "시효기간 경과 + 중단 후에도 경과 → Void" $ do
      -- 20 years total, interrupted at year 8 → 12 years since interruption ≥ 10
      let facts = PrescriptionFacts { pfElapsedDays = 7300
                                    , pfPeriodDays = tenYears
                                    , pfInterruptedAfter = Just 2920 }
      verdict (query act facts) `shouldBe` Void

    it "경계값: 정확히 시효기간 = Void" $ do
      let facts = PrescriptionFacts { pfElapsedDays = tenYears
                                    , pfPeriodDays = tenYears
                                    , pfInterruptedAfter = Nothing }
      verdict (query act facts) `shouldBe` Void

    it "단기소멸시효 (3년) 적용" $ do
      let threeYears = 1095
          facts = PrescriptionFacts { pfElapsedDays = 1100
                                    , pfPeriodDays = threeYears
                                    , pfInterruptedAfter = Nothing }
      verdict (query act facts) `shouldBe` Void

    it "시효중단 시 reasoning chain은 2단계" $ do
      let facts = PrescriptionFacts { pfElapsedDays = 4015
                                    , pfPeriodDays = tenYears
                                    , pfInterruptedAfter = Just 2920 }
          steps = judgmentSteps (query act facts)
      length steps `shouldBe` 2
      stepKind (head steps) `shouldBe` Applied    -- Expiration base (would be Void)
      stepKind (last steps) `shouldBe` Overridden -- Interruption overrides to Valid

    it "중단 없을 시 reasoning chain은 1단계" $ do
      let facts = PrescriptionFacts { pfElapsedDays = 1825
                                    , pfPeriodDays = tenYears
                                    , pfInterruptedAfter = Nothing }
          steps = judgmentSteps (query act facts)
      length steps `shouldBe` 1
      stepKind (head steps) `shouldBe` Applied
