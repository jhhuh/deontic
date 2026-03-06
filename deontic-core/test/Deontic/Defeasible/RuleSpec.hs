{-# LANGUAGE OverloadedStrings #-}
module Deontic.Defeasible.RuleSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule

spec :: Spec
spec = do
  describe "Rule" $ do
    let art5_1 = ArticleRef "민법" 5 (Just 1)
        art5_2 = ArticleRef "민법" 5 (Just 2)
        minor = PersonId "김철수"

    it "can be created with preconditions and conclusion" $ do
      let rule = Rule
            { ruleId = art5_1
            , precondition = \fs -> IsMinor minor `Set.member` fs
            , conclusion = JVoidable [art5_1]
            , defeatedBy = [art5_2]
            }
      ruleId rule `shouldBe` art5_1
      defeatedBy rule `shouldBe` [art5_2]

    it "can evaluate preconditions against facts" $ do
      let rule = Rule
            { ruleId = art5_1
            , precondition = \fs -> IsMinor minor `Set.member` fs
            , conclusion = JVoidable [art5_1]
            , defeatedBy = []
            }
          facts = Set.fromList [IsMinor minor]
      applicable rule facts `shouldBe` True
      applicable rule Set.empty `shouldBe` False
