module Deontic.Civil.CancellationSpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Cancellation ()

spec :: Spec
spec = do
  describe "취소/추인 (§141, §143-§145)" $ do
    let actId = ActId "매매계약"
        voidableAct = CancellableAct actId Voidable
        validAct    = CancellableAct actId Valid
        baseFacts = CancellationFacts
          { cnfCancelled          = False
          , cnfRatified           = False
          , cnfCauseCeased        = False
          , cnfRatifierIsGuardian = False
          , cnfConstructive       = Nothing
          , cnfObjectionReserved  = False
          }

    it "§141: 취소 → Void (소급 무효)" $ do
      let j = query voidableAct baseFacts { cnfCancelled = True }
      verdict j `shouldBe` Void

    it "prior Valid + 취소 → Valid (취소 대상 아님)" $ do
      let j = query validAct baseFacts { cnfCancelled = True }
      verdict j `shouldBe` Valid

    it "Voidable + 아무 조치 없음 → Voidable (그대로)" $ do
      let j = query voidableAct baseFacts
      verdict j `shouldBe` Voidable

    it "§143: 추인 + 원인 소멸 → Valid" $ do
      let j = query voidableAct baseFacts
                { cnfRatified = True
                , cnfCauseCeased = True
                }
      verdict j `shouldBe` Valid

    it "§144①: 추인 + 원인 미소멸 → Voidable (추인 무효)" $ do
      let j = query voidableAct baseFacts
                { cnfRatified = True
                , cnfCauseCeased = False
                }
      verdict j `shouldBe` Voidable

    it "§144②: 후견인 추인 → Valid (원인 소멸 불요)" $ do
      let j = query voidableAct baseFacts
                { cnfRatified = True
                , cnfRatifierIsGuardian = True
                }
      verdict j `shouldBe` Valid

    it "§145: 법정추인 (이행) → Valid" $ do
      let j = query voidableAct baseFacts
                { cnfConstructive = Just FullOrPartialPerformance }
      verdict j `shouldBe` Valid

    it "§145: 법정추인 (강제집행) → Valid" $ do
      let j = query voidableAct baseFacts
                { cnfConstructive = Just CompulsoryExecution }
      verdict j `shouldBe` Valid

    it "§145 단서: 이의 보류 → Voidable (법정추인 안됨)" $ do
      let j = query voidableAct baseFacts
                { cnfConstructive = Just FullOrPartialPerformance
                , cnfObjectionReserved = True
                }
      verdict j `shouldBe` Voidable

    it "§141: 취소의 근거조문은 §141" $ do
      let j = query voidableAct baseFacts { cnfCancelled = True }
          steps = judgmentSteps j
      articleNumber (stepArticle (head steps)) `shouldBe` 141
