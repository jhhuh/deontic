module Deontic.Civil.AcquisitivePrescriptionSpec (spec) where

import Test.Hspec
import Data.Time.Calendar (fromGregorian)
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.AcquisitivePrescription ()

spec :: Spec
spec = do
  describe "취득시효 (§245)" $ do
    let actor = PersonId "갑"
        actId = ActId "토지취득"
        act   = AcqPrescriptionAct actor actId
        -- 점유 개시일: 2000-04-01
        startDate = fromGregorian 2000 4 1
        fullFacts = AcqPrescFacts
          { apfStartDate      = startDate
          , apfCurrentDate    = fromGregorian 2025 4 1  -- 25년 후
          , apfGoodFaith      = True
          , apfNoNegligence   = True
          , apfPeaceful       = True
          , apfPublic         = True
          , apfSelfPossession = True
          }

    it "§245①: 20년 이상 평온·공연·자주점유 → Valid" $ do
      let j = query act fullFacts
      verdict j `shouldBe` Valid

    it "§245①: 19년 + 악의 → Void (20년 미달, 단기시효도 불인정)" $ do
      let j = query act fullFacts
                { apfCurrentDate = fromGregorian 2019 4 1  -- 19년
                , apfGoodFaith = False
                }
      verdict j `shouldBe` Void

    it "§245①: 자주점유 아님 → Void" $ do
      let j = query act fullFacts { apfSelfPossession = False }
      verdict j `shouldBe` Void

    it "§245②: 10년 + 선의·무과실 → Valid (단기취득시효)" $ do
      let j = query act fullFacts
                { apfCurrentDate = fromGregorian 2012 4 1 }  -- 12년
      verdict j `shouldBe` Valid

    it "§245②: 10년 + 악의 → Void (단기취득시효 불인정)" $ do
      let j = query act fullFacts
                { apfCurrentDate = fromGregorian 2012 4 1
                , apfGoodFaith = False
                }
      verdict j `shouldBe` Void

    it "§245②: 10년 + 과실 → Void (단기취득시효 불인정)" $ do
      let j = query act fullFacts
                { apfCurrentDate = fromGregorian 2012 4 1
                , apfNoNegligence = False
                }
      verdict j `shouldBe` Void

    it "§245②: 단기취득시효의 근거조문은 §245②" $ do
      let j = query act fullFacts
                { apfCurrentDate = fromGregorian 2012 4 1 }
          steps = judgmentSteps j
      articleNumber (stepArticle (last steps)) `shouldBe` 245
      articleParagraph (stepArticle (last steps)) `shouldBe` Just 2

    it "§245: 9년 + 선의·무과실 → Void (단기시효도 미달)" $ do
      let j = query act fullFacts
                { apfCurrentDate = fromGregorian 2009 4 1 }  -- 9년
      verdict j `shouldBe` Void
