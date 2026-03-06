module Deontic.Civil.PossessionSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Possession ()

spec :: Spec
spec = do
  describe "점유 추정 — Rebuttable Presumptions (§197, §200)" $ do
    let person = PersonId "점유자"
        actId  = ActId "점유"

    it "반증 없음 → Valid (추정 유지)" $ do
      let j = query (PossessionAct person actId) Set.empty
      verdict j `shouldBe` Valid

    it "악의 점유 → Voidable (§197 반증)" $ do
      let j = query (PossessionAct person actId) (Set.singleton BadFaith)
      verdict j `shouldBe` Voidable

    it "강폭 점유 → Voidable (§197 반증)" $ do
      let j = query (PossessionAct person actId) (Set.singleton ViolentPossession)
      verdict j `shouldBe` Voidable

    it "은비 점유 → Voidable (§197 반증)" $ do
      let j = query (PossessionAct person actId) (Set.singleton ClandestinePossession)
      verdict j `shouldBe` Voidable

    it "타주점유 → Voidable (§200 반증)" $ do
      let j = query (PossessionAct person actId) (Set.singleton NoOwnershipIntent)
      verdict j `shouldBe` Voidable

    it "반증 시 reasoning chain은 2단계" $ do
      let j = query (PossessionAct person actId) (Set.singleton BadFaith)
          steps = judgmentSteps j
      length steps `shouldBe` 2
      stepKind (head steps) `shouldBe` Applied    -- Presumption base
      stepKind (last steps) `shouldBe` Overridden -- Rebuttal override

    it "반증 없을 시 reasoning chain은 1단계 (delegate → base)" $ do
      let j = query (PossessionAct person actId) Set.empty
          steps = judgmentSteps j
      length steps `shouldBe` 1
      stepKind (head steps) `shouldBe` Applied    -- Presumption base only
