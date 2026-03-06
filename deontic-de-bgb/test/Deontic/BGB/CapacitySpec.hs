module Deontic.BGB.CapacitySpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.BGB.Types
import Deontic.BGB.Capacity ()

spec :: Spec
spec = do
  describe "Geschäftsfähigkeit — BGB §104-§113" $ do
    let person = PersonId "Max"
        actId  = ActId "Kaufvertrag"
        act    = CapacityAct person actId

    it "§104(1): unter 7 → Void (geschäftsunfähig)" $ do
      let facts = Set.singleton (UnderSeven person)
      verdict (query act facts) `shouldBe` Void

    it "§104(2): dauerhafte Störung → Void" $ do
      let facts = Set.singleton (PermanentlyIncapable person)
      verdict (query act facts) `shouldBe` Void

    it "§106: Minderjährig ohne Einwilligung → Voidable" $ do
      let facts = Set.singleton (IsMinor person)
      verdict (query act facts) `shouldBe` Voidable

    it "§106: Minderjährig mit Einwilligung → Valid" $ do
      let facts = Set.fromList [IsMinor person, LegalRepConsent person actId]
      verdict (query act facts) `shouldBe` Valid

    it "§107: lediglich rechtlicher Vorteil → Valid" $ do
      let facts = Set.fromList [IsMinor person, PurelyBeneficial]
      verdict (query act facts) `shouldBe` Valid

    it "§110: Taschengeld → Valid" $ do
      let facts = Set.fromList [IsMinor person, PocketMoney]
      verdict (query act facts) `shouldBe` Valid

    it "volle Geschäftsfähigkeit → Valid" $ do
      verdict (query act Set.empty) `shouldBe` Valid

    it "§107 reasoning chain has 2 steps" $ do
      let facts = Set.fromList [IsMinor person, PurelyBeneficial]
          steps = judgmentSteps (query act facts)
      length steps `shouldBe` 2
      stepKind (head steps) `shouldBe` Applied    -- §106 base
      stepKind (last steps) `shouldBe` Overridden -- §107 proviso

    it "§110 reasoning chain has 3 steps (overrides through proviso)" $ do
      let facts = Set.fromList [IsMinor person, PocketMoney]
          steps = judgmentSteps (query act facts)
      -- SpecialRule delegates, Proviso delegates, Base applies
      -- Wait: PocketMoney is SpecialRule, it overrides.
      -- So: Base (Voidable) → Proviso delegates → SpecialRule overrides (Valid)
      length steps `shouldBe` 2
      stepKind (head steps) `shouldBe` Applied    -- Base
      stepKind (last steps) `shouldBe` Overridden -- SpecialRule
