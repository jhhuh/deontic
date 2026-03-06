module Deontic.Civil.SaleWarrantySpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.SaleWarranty ()

spec :: Spec
spec = do
  describe "하자담보책임 (§580-§582)" $ do
    let actor = PersonId "매수인"
        actId = ActId "매매계약"
        act   = WarrantyAct actor actId
        baseFacts = WarrantyFacts
          { wfDefectExists   = True
          , wfSignificant    = False
          , wfBuyerKnew      = False
          , wfNotifiedInTime = True
          }

    it "§580①: 하자 + 통지 → Voidable (손해배상)" $ do
      let j = query act baseFacts
      verdict j `shouldBe` Voidable

    it "§580①: 중대한 하자 → Void (해제 가능)" $ do
      let j = query act baseFacts { wfSignificant = True }
      verdict j `shouldBe` Void

    it "§580: 하자 없음 → Valid" $ do
      let j = query act baseFacts { wfDefectExists = False }
      verdict j `shouldBe` Valid

    it "§582: 6월 내 미통지 → Valid (실권)" $ do
      let j = query act baseFacts { wfNotifiedInTime = False }
      verdict j `shouldBe` Valid

    it "§580②: 매수인 악의 → Valid (면책)" $ do
      let j = query act baseFacts { wfBuyerKnew = True }
      verdict j `shouldBe` Valid

    it "§580②: 매수인 악의 + 중대한 하자도 → Valid (면책)" $ do
      let j = query act baseFacts { wfSignificant = True, wfBuyerKnew = True }
      verdict j `shouldBe` Valid

    it "§580②: 매수인 악의 면책의 근거조문은 §580②" $ do
      let j = query act baseFacts { wfBuyerKnew = True }
          steps = judgmentSteps j
      articleNumber (stepArticle (last steps)) `shouldBe` 580
      articleParagraph (stepArticle (last steps)) `shouldBe` Just 2

    it "§580②: 하자 없으면 매수인 악의라도 Valid (delegate)" $ do
      let j = query act baseFacts { wfDefectExists = False, wfBuyerKnew = True }
      verdict j `shouldBe` Valid
