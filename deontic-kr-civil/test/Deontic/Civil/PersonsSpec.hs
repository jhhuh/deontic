{-# LANGUAGE OverloadedStrings #-}
module Deontic.Civil.PersonsSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Query
import Deontic.Civil.Persons

spec :: Spec
spec = do
  describe "민법 2장 인 — Persons" $ do
    let minor = PersonId "김철수"
        guardian = PersonId "김부모"
        act1 = ActId "sale-001"

    it "§5①: minor's juristic act without consent is voidable" $ do
      let facts = Set.fromList
            [ IsMinor minor
            , PerformsAct minor act1
            ]
          results = query personsCode facts
      any (\(j, _) -> isVoidable j) results `shouldBe` True

    it "§5②: minor merely acquiring rights needs no consent" $ do
      let facts = Set.fromList
            [ IsMinor minor
            , PerformsAct minor act1
            , Custom "merely-acquires-right"
            ]
          results = query personsCode facts
      any (\(j, _) -> isValid j) results `shouldBe` True
      any (\(j, _) -> isVoidable j) results `shouldBe` False

    it "§5①: minor with guardian consent is valid" $ do
      let facts = Set.fromList
            [ IsMinor minor
            , PerformsAct minor act1
            , HasGuardian minor guardian
            , HasConsent guardian act1
            ]
          results = query personsCode facts
      any (\(j, _) -> isValid j) results `shouldBe` True
