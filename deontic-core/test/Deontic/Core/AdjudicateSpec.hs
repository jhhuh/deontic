{-# LANGUAGE OverloadedStrings #-}
module Deontic.Core.AdjudicateSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Layer
import Deontic.Core.Adjudicate

-- Test fact type
data TestFact = TestException deriving (Eq, Ord)

-- Test act type
data TestAct = TestAct

type instance Facts TestAct = Set.Set TestFact
type instance Resolvable TestAct = '[Proviso, Base]

instance Adjudicate TestAct '[Base] where
  adjudicate _ _ = JBase Voidable (ArticleRef "test" 1 Nothing) "base rule"

instance Adjudicate TestAct rest
      => Adjudicate TestAct (Proviso ': rest) where
  adjudicate act facts
    | TestException `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "test" 1 (Just 2))
                  "exception applies"
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

spec :: Spec
spec = do
  describe "Adjudicate" $ do
    it "base layer returns base verdict" $ do
      let j = adjudicate @TestAct @'[Base] TestAct Set.empty
      verdict j `shouldBe` Voidable

    it "proviso layer delegates when no exception" $ do
      let j = adjudicate @TestAct @'[Proviso, Base] TestAct Set.empty
      verdict j `shouldBe` Voidable

    it "proviso layer overrides when exception present" $ do
      let j = adjudicate @TestAct @'[Proviso, Base] TestAct
                (Set.singleton TestException)
      verdict j `shouldBe` Valid

    it "query uses Resolvable to pick layers" $ do
      let j = query TestAct Set.empty
      verdict j `shouldBe` Voidable
