{-# LANGUAGE OverloadedStrings #-}
module Deontic.Civil.IntegrationSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule (Rule)
import Deontic.Query
import Deontic.Civil.Persons (personsRules)
import Deontic.Civil.Acts (actsRules)

-- Combined civil code from all chapters
newtype CivilCode = CivilCode [Rule]

instance LegalCode CivilCode where
  codeRules (CivilCode rs) = rs

civilCode :: CivilCode
civilCode = CivilCode (personsRules ++ actsRules)

spec :: Spec
spec = do
  describe "Combined 민법 총칙 query" $ do
    it "minor's act against good morals is void (§103 overrides §5)" $ do
      let minor = PersonId "김철수"
          act1 = ActId "immoral-sale"
          facts = Set.fromList
            [ IsMinor minor
            , PerformsAct minor act1
            , Custom "contra-bonos-mores"
            ]
          results = query civilCode facts
      -- §103 produces void, §5① produces voidable — both should be present
      any (\(j, _) -> isVoid j) results `shouldBe` True

    it "adult's normal act produces no judgment (no applicable rule)" $ do
      let adult = PersonId "박성인"
          act1 = ActId "normal-sale"
          facts = Set.fromList
            [ IsAdult adult
            , PerformsAct adult act1
            ]
          results = query civilCode facts
      results `shouldBe` []
