{-# LANGUAGE OverloadedStrings #-}
module Deontic.Civil.RenderSpec (spec) where

import Test.Hspec
import qualified Data.Text as T
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Render
import Deontic.Civil.Persons (personsRules)
import Deontic.Civil.Render (KoreanRenderer(..), renderKorean)

spec :: Spec
spec = do
  describe "Korean legal sentence rendering" $ do
    let minor = PersonId "김철수"
        act1 = ActId "매매계약"

    it "renders a voidable judgment for minor without consent" $ do
      let facts = Set.fromList [IsMinor minor, PerformsAct minor act1]
          results = explain personsRules facts
          rendered = renderResult KoreanRenderer (head results)
      rendered `shouldSatisfy` T.isInfixOf "취소할 수 있다"
      rendered `shouldSatisfy` T.isInfixOf "제5조"
      rendered `shouldSatisfy` T.isInfixOf "미성년자가 법률행위를 함에는"
      rendered `shouldSatisfy` T.isInfixOf "김철수"
      rendered `shouldSatisfy` T.isInfixOf "미성년자이다"

    it "renders a valid judgment for minor with consent" $ do
      let guardian = PersonId "김부모"
          facts = Set.fromList
            [ IsMinor minor
            , PerformsAct minor act1
            , HasGuardian minor guardian
            , HasConsent guardian act1
            ]
          results = explain personsRules facts
          rendered = renderResult KoreanRenderer (head results)
      rendered `shouldSatisfy` T.isInfixOf "유효하다"
      rendered `shouldSatisfy` T.isInfixOf "제5조"
