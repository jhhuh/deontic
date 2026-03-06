{-# LANGUAGE OverloadedStrings #-}
module Deontic.QuerySpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule
import Deontic.Query

spec :: Spec
spec = do
  describe "LegalCode typeclass" $ do
    it "can query a simple code" $ do
      let art5_1 = ArticleRef "민법" 5 (Just 1)
          minor = PersonId "김철수"
          code = SimpleCode
            [ Rule
                { ruleId = art5_1
                , sourceText = "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다."
                , precondition = \fs -> IsMinor minor `Set.member` fs
                , conclusion = JVoidable [art5_1]
                , defeatedBy = []
                }
            ]
          facts = Set.fromList [IsMinor minor]
          result = query code facts
      length result `shouldBe` 1
      fst (head result) `shouldBe` JVoidable [art5_1]
