module Deontic.Civil.ActsSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types (JuristicAct(..))
import Deontic.Civil.Acts ()

spec :: Spec
spec = do
  describe "민법 법률행위" $ do
    let person = PersonId "이영희"
        act1 = ActId "계약"

    it "§103: 반사회질서의 법률행위는 무효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [Custom "contra-bonos-mores"])
      verdict j `shouldBe` Void

    it "§104: 불공정한 법률행위는 무효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [Custom "exploitative-act"])
      verdict j `shouldBe` Void

    it "§107①: 비진의 의사표시는 유효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [Custom "hidden-intention"])
      verdict j `shouldBe` Valid

    it "§107②: 상대방이 안 경우 무효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [Custom "hidden-intention", Custom "counterparty-knew"])
      verdict j `shouldBe` Void
