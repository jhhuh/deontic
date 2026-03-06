{-# LANGUAGE OverloadedStrings #-}
module Deontic.Civil.RenderSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render (Renderer(..))
import Deontic.Civil.Types (MinorAct(..), JuristicAct(..), CivilFact(..))
import Deontic.Civil.Persons ()
import Deontic.Civil.Acts ()
import Deontic.Civil.Render (KoreanRenderer(..))

spec :: Spec
spec = do
  describe "KoreanRenderer" $ do
    let renderer = KoreanRenderer

    it "renders Voidable MinorAct judgment in Korean" $ do
      let minor = PersonId "김철수"
          act1 = ActId "매매계약"
          j = query (MinorAct minor act1)
                (Set.fromList [IsMinor minor, PerformsAct minor act1])
          rendered = renderJudgment renderer j
      rendered `shouldSatisfy` T.isInfixOf "취소할 수 있다"
      rendered `shouldSatisfy` T.isInfixOf "민법 제5조"

    it "renders overridden judgment with reasoning chain" $ do
      let person = PersonId "이영희"
          act1 = ActId "계약"
          j = query (JuristicAct person act1)
                (Set.fromList [HiddenIntention, CounterpartyKnew])
          rendered = renderJudgment renderer j
      rendered `shouldSatisfy` T.isInfixOf "무효"
      rendered `shouldSatisfy` T.isInfixOf "민법 제107조"

    it "renders contra-bonos-mores as Void" $ do
      let person = PersonId "박민수"
          act1 = ActId "도박계약"
          j = query (JuristicAct person act1)
                (Set.fromList [ContraBonorsMores])
          rendered = renderJudgment renderer j
      rendered `shouldSatisfy` T.isInfixOf "무효"
      rendered `shouldSatisfy` T.isInfixOf "민법 제103조"
