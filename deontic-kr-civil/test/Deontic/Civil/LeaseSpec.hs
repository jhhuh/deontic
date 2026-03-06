module Deontic.Civil.LeaseSpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Lease ()

spec :: Spec
spec = do
  describe "임대차 (§618, §639, §640)" $ do
    let lessor = PersonId "임대인"
        lessee = PersonId "임차인"
        actId  = ActId "임대차계약"
        act    = LeaseAct lessor lessee actId
        baseFacts = LeaseFacts
          { lfValidContract = True
          , lfRentPaid      = True
          , lfPeriodExpired = False
          , lfContinuedUse  = False
          , lfNoObjection   = False
          , lfTwoRentsLate  = False
          }

    it "§618: 유효한 계약 + 기간 내 → Valid" $ do
      let j = query act baseFacts
      verdict j `shouldBe` Valid

    it "§618: 계약 무효 → Void" $ do
      let j = query act baseFacts { lfValidContract = False }
      verdict j `shouldBe` Void

    it "§618: 기간 만료 → Void" $ do
      let j = query act baseFacts { lfPeriodExpired = True }
      verdict j `shouldBe` Void

    it "§640: 2기 차임 연체 → Void (해지)" $ do
      let j = query act baseFacts { lfTwoRentsLate = True }
      verdict j `shouldBe` Void

    it "§639: 기간 만료 + 계속 사용 + 이의 없음 → Valid (묵시적 갱신)" $ do
      let j = query act baseFacts
                { lfPeriodExpired = True
                , lfContinuedUse  = True
                , lfNoObjection   = True
                }
      verdict j `shouldBe` Valid

    it "§639: 기간 만료 + 계속 사용 + 이의 있음 → Void (갱신 불가)" $ do
      let j = query act baseFacts
                { lfPeriodExpired = True
                , lfContinuedUse  = True
                , lfNoObjection   = False
                }
      verdict j `shouldBe` Void

    it "§639+§640: 묵시적 갱신 중 2기 연체 → Void (해지 우선)" $ do
      let j = query act baseFacts
                { lfPeriodExpired = True
                , lfContinuedUse  = True
                , lfNoObjection   = True
                , lfTwoRentsLate  = True
                }
      verdict j `shouldBe` Void

    it "§639: 묵시적 갱신의 근거조문은 §639" $ do
      let j = query act baseFacts
                { lfPeriodExpired = True
                , lfContinuedUse  = True
                , lfNoObjection   = True
                }
          steps = judgmentSteps j
      articleNumber (stepArticle (last steps)) `shouldBe` 639
