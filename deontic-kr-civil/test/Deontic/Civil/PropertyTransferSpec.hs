module Deontic.Civil.PropertyTransferSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.PropertyTransfer ()

spec :: Spec
spec = do
  describe "물권변동 (§186, §187, §188)" $ do
    let actor = PersonId "갑"
        actId = ActId "소유권이전"
        act   = PropertyTransferAct actor actId

    it "§186: 부동산 + 등기 → Valid" $ do
      let j = query act (Set.fromList [IsRealProperty, HasRegistration])
      verdict j `shouldBe` Valid

    it "§186: 부동산 + 등기 없음 → Void" $ do
      let j = query act (Set.singleton IsRealProperty)
      verdict j `shouldBe` Void

    it "§187: 부동산 + 상속 → Valid (등기 불요)" $ do
      let j = query act (Set.fromList [IsRealProperty, ByInheritance])
      verdict j `shouldBe` Valid

    it "§187: 부동산 + 판결 → Valid (등기 불요)" $ do
      let j = query act (Set.fromList [IsRealProperty, ByCourtOrder])
      verdict j `shouldBe` Valid

    it "§187: 부동산 + 공매 → Valid (등기 불요)" $ do
      let j = query act (Set.fromList [IsRealProperty, ByPublicAuction])
      verdict j `shouldBe` Valid

    it "§187: 부동산 + 수용 → Valid (등기 불요)" $ do
      let j = query act (Set.fromList [IsRealProperty, ByExpropriation])
      verdict j `shouldBe` Valid

    it "§188: 동산 + 인도 → Valid" $ do
      let j = query act (Set.fromList [IsMovableProperty, HasDelivery])
      verdict j `shouldBe` Valid

    it "§188: 동산 + 인도 없음 → Void" $ do
      let j = query act (Set.singleton IsMovableProperty)
      verdict j `shouldBe` Void

    it "§187: 상속에 의한 물권변동의 근거조문은 §187" $ do
      let j = query act (Set.fromList [IsRealProperty, ByInheritance])
          steps = judgmentSteps j
      articleNumber (stepArticle (last steps)) `shouldBe` 187

    it "§187: 상속은 §186 base를 override함" $ do
      let j = query act (Set.fromList [IsRealProperty, ByInheritance])
          steps = judgmentSteps j
      length steps `shouldBe` 2
      stepKind (last steps) `shouldBe` Overridden
