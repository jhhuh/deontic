{-# LANGUAGE OverloadedStrings #-}
module Deontic.Core.JudgmentSpec (spec) where

import Test.Hspec
import Data.Text (Text)
import Deontic.Core.Types
import Deontic.Core.Judgment

spec :: Spec
spec = do
  describe "Judgment" $ do
    let art5 = ArticleRef "민법" 5 (Just 1)
        art5_2 = ArticleRef "민법" 5 (Just 2)

    it "can represent a valid act" $ do
      let j = JValid [art5_2]
      isValid j `shouldBe` True
      citations j `shouldBe` [art5_2]

    it "can represent a void act" $ do
      let j = JVoid [art5]
      isVoid j `shouldBe` True

    it "can represent a voidable act" $ do
      let j = JVoidable [art5]
      isVoidable j `shouldBe` True

  describe "ProofTree" $ do
    it "can build a derivation tree" $ do
      let art5 = ArticleRef "민법" 5 (Just 1)
          art8 = ArticleRef "민법" 8 Nothing
          tree = Derived art5 [Leaf art8]
      rootArticle tree `shouldBe` art5
