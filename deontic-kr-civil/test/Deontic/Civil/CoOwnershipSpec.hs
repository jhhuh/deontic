module Deontic.Civil.CoOwnershipSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types
import Deontic.Civil.CoOwnership ()

spec :: Spec
spec = do
  describe "공유물의 처분 — Universal Quantification (§264)" $ do
    let actId = ActId "토지처분"
        act   = CoOwnershipAct actId
        갑    = PersonId "갑"
        을    = PersonId "을"
        병    = PersonId "병"

    it "전원 동의 → Valid" $ do
      let facts = CoOwnershipFacts
            { cofOwners    = [갑, 을, 병]
            , cofConsented = Set.fromList [갑, 을, 병]
            }
      verdict (query act facts) `shouldBe` Valid

    it "1인 미동의 → Void" $ do
      let facts = CoOwnershipFacts
            { cofOwners    = [갑, 을, 병]
            , cofConsented = Set.fromList [갑, 을]  -- 병 미동의
            }
      verdict (query act facts) `shouldBe` Void

    it "전원 미동의 → Void" $ do
      let facts = CoOwnershipFacts
            { cofOwners    = [갑, 을, 병]
            , cofConsented = Set.empty
            }
      verdict (query act facts) `shouldBe` Void

    it "단독 소유자 동의 → Valid" $ do
      let facts = CoOwnershipFacts
            { cofOwners    = [갑]
            , cofConsented = Set.singleton 갑
            }
      verdict (query act facts) `shouldBe` Valid

    it "공유자 없음 (vacuous truth) → Valid" $ do
      let facts = CoOwnershipFacts
            { cofOwners    = []
            , cofConsented = Set.empty
            }
      verdict (query act facts) `shouldBe` Valid
