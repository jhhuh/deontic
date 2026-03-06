module Deontic.Core.CapacitySpec (spec) where

import Test.Hspec
import Deontic.Core.Capacity

spec :: Spec
spec = do
  describe "CapacityLevel" $ do
    it "orders capacity levels" $ do
      Full `shouldSatisfy` (> Limited)
      Limited `shouldSatisfy` (> None)
