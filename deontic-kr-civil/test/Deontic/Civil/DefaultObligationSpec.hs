module Deontic.Civil.DefaultObligationSpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.DefaultObligation ()

spec :: Spec
spec = do
  describe "채무불이행 (§387-§390)" $ do
    let creditor = PersonId "갑"
        debtor   = PersonId "을"
        actId    = ActId "대금지급"
        act      = DefaultAct creditor debtor actId
        baseFacts = DefaultFacts
          { dfPerformanceDue = True
          , dfNonPerformance = True
          , dfDebtorFault    = True
          , dfImpossible     = False
          , dfCreditorFault  = False
          }

    it "§387: 이행기 도래 + 불이행 + 귀책 → Void (이행지체)" $ do
      let j = query act baseFacts
      verdict j `shouldBe` Void

    it "§390: 이행불능 + 귀책 → Void (전보배상)" $ do
      let j = query act baseFacts { dfImpossible = True }
      verdict j `shouldBe` Void

    it "§387: 이행기 미도래 → Valid" $ do
      let j = query act baseFacts { dfPerformanceDue = False }
      verdict j `shouldBe` Valid

    it "§387: 이행 완료 → Valid" $ do
      let j = query act baseFacts { dfNonPerformance = False }
      verdict j `shouldBe` Valid

    it "§390: 귀책사유 없음 → Valid (면책)" $ do
      let j = query act baseFacts { dfDebtorFault = False }
      verdict j `shouldBe` Valid

    it "§390: 채권자 과실 → Voidable (감경)" $ do
      let j = query act baseFacts { dfCreditorFault = True }
      verdict j `shouldBe` Voidable

    it "§390: 채권자 과실 + 귀책 없음 → Valid (면책이 우선)" $ do
      let j = query act baseFacts { dfDebtorFault = False, dfCreditorFault = True }
      verdict j `shouldBe` Valid

    it "§390: 채권자 과실 감경의 근거조문은 §390" $ do
      let j = query act baseFacts { dfCreditorFault = True }
          steps = judgmentSteps j
      articleNumber (stepArticle (last steps)) `shouldBe` 390
