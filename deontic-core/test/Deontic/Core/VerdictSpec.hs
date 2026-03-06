module Deontic.Core.VerdictSpec (spec) where

import Test.Hspec
import Test.QuickCheck

import Deontic.Core.Verdict

instance Arbitrary Verdict where
  arbitrary = elements [Valid, Void, Voidable, Pending]

spec :: Spec
spec = do
  describe "verdictMeet" $ do
    it "is commutative" $ property $ \a b ->
      verdictMeet a b == verdictMeet b a

    it "is associative" $ property $ \a b c ->
      verdictMeet a (verdictMeet b c) == verdictMeet (verdictMeet a b) c

    it "Valid is identity" $ property $ \a ->
      verdictMeet Valid a == a

    it "Void is absorbing" $ property $ \a ->
      verdictMeet Void a == Void

    it "result is at least as severe as each input" $ property $ \a b ->
      let m = verdictMeet a b
          severity v = case v of
            Valid    -> 0 :: Int
            Voidable -> 1
            Pending  -> 2
            Void     -> 3
      in severity m >= severity a && severity m >= severity b

    it "Void > Pending > Voidable > Valid" $ do
      verdictMeet Void Pending `shouldBe` Void
      verdictMeet Pending Voidable `shouldBe` Pending
      verdictMeet Voidable Valid `shouldBe` Voidable
