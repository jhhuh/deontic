module Deontic.Civil.TortSpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Tort ()

allElements :: TortFacts
allElements = TortFacts True True True True False

spec :: Spec
spec = do
  describe "불법행위 — Tort Liability (§750, §763→§396)" $ do
    let victim     = PersonId "피해자"
        tortfeasor = PersonId "가해자"
        actId      = ActId "사고"
        act        = TortAct victim tortfeasor actId

    it "4요건 충족 → Void (배상책임, §750)" $ do
      verdict (query act allElements) `shouldBe` Void

    it "과실 없음 → Valid (책임 없음)" $ do
      let facts = allElements { tfFault = False }
      verdict (query act facts) `shouldBe` Valid

    it "위법성 없음 → Valid" $ do
      let facts = allElements { tfUnlawful = False }
      verdict (query act facts) `shouldBe` Valid

    it "손해 없음 → Valid" $ do
      let facts = allElements { tfDamage = False }
      verdict (query act facts) `shouldBe` Valid

    it "인과관계 없음 → Valid" $ do
      let facts = allElements { tfCausation = False }
      verdict (query act facts) `shouldBe` Valid

    it "4요건 + 피해자 과실 → Voidable (과실상계, §396)" $ do
      let facts = allElements { tfVictimNeg = True }
      verdict (query act facts) `shouldBe` Voidable

    it "요건 불충족 + 피해자 과실 → Valid (과실상계 적용 안됨)" $ do
      -- contributory negligence only matters when tort is established
      let facts = TortFacts False True True True True
      verdict (query act facts) `shouldBe` Valid

    it "과실상계 시 reasoning chain은 2단계" $ do
      let facts = allElements { tfVictimNeg = True }
          steps = judgmentSteps (query act facts)
      length steps `shouldBe` 2
      stepKind (head steps) `shouldBe` Applied    -- §750 base
      stepKind (last steps) `shouldBe` Overridden -- §396 override
