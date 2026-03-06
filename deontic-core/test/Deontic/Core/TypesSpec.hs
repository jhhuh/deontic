{-# LANGUAGE OverloadedStrings #-}
module Deontic.Core.TypesSpec (spec) where

import Test.Hspec
import Deontic.Core.Types

spec :: Spec
spec = do
  describe "PersonId" $ do
    it "can be created and compared" $ do
      let p1 = PersonId "person-1"
          p2 = PersonId "person-2"
      p1 `shouldNotBe` p2
      p1 `shouldBe` PersonId "person-1"

  describe "ArticleRef" $ do
    it "represents a statute article reference" $ do
      let ref = ArticleRef "민법" 5 (Just 1)
      articleStatute ref `shouldBe` "민법"
      articleNumber ref `shouldBe` 5
      articleParagraph ref `shouldBe` Just 1
