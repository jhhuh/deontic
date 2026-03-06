module Deontic.Civil.PrescriptionSpec (spec) where

import Test.Hspec
import Data.Time.Calendar (fromGregorian, addGregorianYearsClip)
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Prescription ()

spec :: Spec
spec = do
  describe "소멸시효 — Prescription (§162, §168, §174)" $ do
    let creditor = PersonId "채권자"
        claimId  = ActId "대여금채권"
        act      = PrescriptionAct creditor claimId
        -- 기준일: 2010-01-15 (채권 발생일)
        claimDate = fromGregorian 2010 1 15

    it "시효기간 내 → Valid (소멸시효 미완성)" $ do
      let facts = PrescriptionFacts
            { pfClaimDate   = claimDate
            , pfCurrentDate = fromGregorian 2015 1 15  -- 5년 후
            , pfPeriodYears = 10
            , pfInterruptedOn = Nothing
            }
      verdict (query act facts) `shouldBe` Valid

    it "시효기간 경과 → Void (소멸시효 완성, §162①)" $ do
      let facts = PrescriptionFacts
            { pfClaimDate   = claimDate
            , pfCurrentDate = fromGregorian 2021 3 1  -- 11년 후
            , pfPeriodYears = 10
            , pfInterruptedOn = Nothing
            }
      verdict (query act facts) `shouldBe` Void

    it "시효기간 경과 but 중단 → Valid (§174 시효중단)" $ do
      -- 11년 경과, but 8년차에 중단 → 중단일로부터 3년만 경과 < 10년
      let facts = PrescriptionFacts
            { pfClaimDate   = claimDate
            , pfCurrentDate = fromGregorian 2021 3 1
            , pfPeriodYears = 10
            , pfInterruptedOn = Just (fromGregorian 2018 1 15)  -- 8년차 중단
            }
      verdict (query act facts) `shouldBe` Valid

    it "시효기간 경과 + 중단 후에도 경과 → Void" $ do
      -- 8년차에 중단, 그 후 12년 경과 (총 20년)
      let facts = PrescriptionFacts
            { pfClaimDate   = claimDate
            , pfCurrentDate = fromGregorian 2030 3 1
            , pfPeriodYears = 10
            , pfInterruptedOn = Just (fromGregorian 2018 1 15)
            }
      verdict (query act facts) `shouldBe` Void

    it "경계값: 정확히 시효 만료일 = Void" $ do
      -- 2010-01-15 + 10년 = 2020-01-15
      let facts = PrescriptionFacts
            { pfClaimDate   = claimDate
            , pfCurrentDate = fromGregorian 2020 1 15
            , pfPeriodYears = 10
            , pfInterruptedOn = Nothing
            }
      verdict (query act facts) `shouldBe` Void

    it "경계값: 시효 만료 전날 = Valid" $ do
      let facts = PrescriptionFacts
            { pfClaimDate   = claimDate
            , pfCurrentDate = fromGregorian 2020 1 14
            , pfPeriodYears = 10
            , pfInterruptedOn = Nothing
            }
      verdict (query act facts) `shouldBe` Valid

    it "단기소멸시효 (3년) 적용" $ do
      let facts = PrescriptionFacts
            { pfClaimDate   = claimDate
            , pfCurrentDate = fromGregorian 2013 6 1  -- 3년 초과
            , pfPeriodYears = 3
            , pfInterruptedOn = Nothing
            }
      verdict (query act facts) `shouldBe` Void

    it "시효중단 시 reasoning chain은 2단계" $ do
      let facts = PrescriptionFacts
            { pfClaimDate   = claimDate
            , pfCurrentDate = fromGregorian 2021 3 1
            , pfPeriodYears = 10
            , pfInterruptedOn = Just (fromGregorian 2018 1 15)
            }
          steps = judgmentSteps (query act facts)
      length steps `shouldBe` 2
      stepKind (head steps) `shouldBe` Applied    -- Expiration base (would be Void)
      stepKind (last steps) `shouldBe` Overridden -- Interruption overrides to Valid

    it "중단 없을 시 reasoning chain은 1단계" $ do
      let facts = PrescriptionFacts
            { pfClaimDate   = claimDate
            , pfCurrentDate = fromGregorian 2015 1 15
            , pfPeriodYears = 10
            , pfInterruptedOn = Nothing
            }
          steps = judgmentSteps (query act facts)
      length steps `shouldBe` 1
      stepKind (head steps) `shouldBe` Applied

    it "§157: 윤년 처리 — 2020-02-29 + 1년 = 2021-02-28" $ do
      -- 윤일에 발생한 채권의 1년 시효
      let leapFacts = PrescriptionFacts
            { pfClaimDate   = fromGregorian 2020 2 29
            , pfCurrentDate = fromGregorian 2021 2 28
            , pfPeriodYears = 1
            , pfInterruptedOn = Nothing
            }
      verdict (query act leapFacts) `shouldBe` Void
      -- addGregorianYearsClip 1 (2020-02-29) = 2021-02-28
