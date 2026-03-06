module Deontic.Civil.ActsSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Query
import Deontic.Civil.Acts

spec :: Spec
spec = do
  describe "민법 4장 법률행위" $ do
    let person = PersonId "이영희"
        act1 = ActId "contract-001"

    it "§103: act against good morals is void" $ do
      let facts = Set.fromList
            [ PerformsAct person act1
            , Custom "contra-bonos-mores"
            ]
          results = query actsCode facts
      any (\(j, _) -> isVoid j) results `shouldBe` True

    it "§104: unfair juristic act (폭리행위) is void" $ do
      let facts = Set.fromList
            [ PerformsAct person act1
            , Custom "exploitative-act"
            ]
          results = query actsCode facts
      any (\(j, _) -> isVoid j) results `shouldBe` True

    it "§107①: act with hidden intention is valid" $ do
      let facts = Set.fromList
            [ PerformsAct person act1
            , Custom "hidden-intention"
            ]
          results = query actsCode facts
      any (\(j, _) -> isValid j) results `shouldBe` True

    it "§107②: hidden intention known to counterparty is void" $ do
      let facts = Set.fromList
            [ PerformsAct person act1
            , Custom "hidden-intention"
            , Custom "counterparty-knew"
            ]
          results = query actsCode facts
      any (\(j, _) -> isVoid j) results `shouldBe` True
      any (\(j, _) -> isValid j) results `shouldBe` False
