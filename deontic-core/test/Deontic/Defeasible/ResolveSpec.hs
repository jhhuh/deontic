{-# LANGUAGE OverloadedStrings #-}
module Deontic.Defeasible.ResolveSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule
import Deontic.Defeasible.Resolve

spec :: Spec
spec = do
  describe "resolve" $ do
    let art5_1 = ArticleRef "민법" 5 (Just 1)
        art5_2 = ArticleRef "민법" 5 (Just 2)
        minor = PersonId "김철수"

    it "returns undefeated conclusions" $ do
      let r1 = Rule
            { ruleId = art5_1
            , precondition = \fs -> IsMinor minor `Set.member` fs
            , conclusion = JVoidable [art5_1]
            , defeatedBy = [art5_2]
            }
          facts = Set.fromList [IsMinor minor]
          results = resolve [r1] facts
      length results `shouldBe` 1
      fst (head results) `shouldBe` JVoidable [art5_1]

    it "defeats a rule when its defeater is applicable" $ do
      let r1 = Rule
            { ruleId = art5_1
            , precondition = \fs -> IsMinor minor `Set.member` fs
            , conclusion = JVoidable [art5_1]
            , defeatedBy = [art5_2]
            }
          r2 = Rule
            { ruleId = art5_2
            , precondition = \fs -> IsMinor minor `Set.member` fs
                                 && Custom "merely-acquires-right" `Set.member` fs
            , conclusion = JValid [art5_2]
            , defeatedBy = []
            }
          facts = Set.fromList [IsMinor minor, Custom "merely-acquires-right"]
          results = resolve [r1, r2] facts
      length results `shouldBe` 1
      fst (head results) `shouldBe` JValid [art5_2]

    it "returns nothing when no rules are applicable" $ do
      let r1 = Rule
            { ruleId = art5_1
            , precondition = \fs -> IsMinor minor `Set.member` fs
            , conclusion = JVoidable [art5_1]
            , defeatedBy = []
            }
      resolve [r1] Set.empty `shouldBe` []
