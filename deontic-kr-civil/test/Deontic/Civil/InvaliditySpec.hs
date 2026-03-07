module Deontic.Civil.InvaliditySpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Invalidity ()

spec :: Spec
spec = do
  describe "법률행위의 일부무효/전환/추인 (§137-§139)" $ do
    let actId = ActId "매매계약"
        act   = PartialInvalidityAct actId
        baseFacts = PartialInvalidityFacts
          { pifPartVoid              = True
          , pifHypotheticalIntent    = False
          , pifMeetsOtherReqs        = False
          , pifConversionIntent      = False
          , pifRatifiedWithKnowledge = False
          }

    it "§137 본문: 일부 무효 → Void (전부 무효)" $ do
      let j = query act baseFacts
      verdict j `shouldBe` Void

    it "§137: 일부 무효 아님 → Valid" $ do
      let j = query act baseFacts { pifPartVoid = False }
      verdict j `shouldBe` Valid

    it "§137 단서: 가정적 의사 인정 → Valid (나머지 유효)" $ do
      let j = query act baseFacts { pifHypotheticalIntent = True }
      verdict j `shouldBe` Valid

    it "§138: 다른 행위 요건 구비 + 의욕 → Valid (전환)" $ do
      let j = query act baseFacts
                { pifMeetsOtherReqs = True
                , pifConversionIntent = True
                }
      verdict j `shouldBe` Valid

    it "§138: 요건 구비하나 의욕 없음 → Void (전환 안됨)" $ do
      let j = query act baseFacts
                { pifMeetsOtherReqs = True
                , pifConversionIntent = False
                }
      verdict j `shouldBe` Void

    it "§139: 무효 알고 추인 → Valid (새로운 법률행위)" $ do
      let j = query act baseFacts { pifRatifiedWithKnowledge = True }
      verdict j `shouldBe` Valid

    it "§139: 무효 모르고 추인 → Void (추인 무효)" $ do
      let j = query act baseFacts { pifRatifiedWithKnowledge = False }
      verdict j `shouldBe` Void

    it "§138: 전환의 근거조문은 §138" $ do
      let j = query act baseFacts
                { pifMeetsOtherReqs = True
                , pifConversionIntent = True
                }
          steps = judgmentSteps j
      articleNumber (stepArticle (last steps)) `shouldBe` 138
