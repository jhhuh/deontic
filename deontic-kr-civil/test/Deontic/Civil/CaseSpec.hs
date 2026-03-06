module Deontic.Civil.CaseSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Acts ()
import Deontic.Civil.Agency ()

spec :: Spec
spec = do
  describe "combineVerdicts — 사안의 종합 판단" $ do
    let person = PersonId "갑"
        actId = ActId "계약"

    it "사기 + 반사회질서 → Void (가장 중한 판단)" $ do
      let js = [ SomeJudgment $ query (FraudAct person actId) Set.empty
               , SomeJudgment $ query (JuristicAct person actId)
                   (Set.singleton ContraBonorsMores)
               ]
      combineVerdicts js `shouldBe` Void

    it "무권대리 + 착오 → Pending (Pending > Voidable)" $ do
      let principal = PersonId "본인"
          agent = PersonId "무권대리인"
          js = [ SomeJudgment $ query (UnauthAgencyAct principal agent actId)
                   Set.empty
               , SomeJudgment $ query (MistakeAct person actId)
                   Set.empty
               ]
      combineVerdicts js `shouldBe` Pending

    it "모든 판단이 유효 → Valid" $ do
      let principal = PersonId "본인"
          agent = PersonId "대리인"
          js = [ SomeJudgment $ query (JuristicAct person actId) Set.empty
               , SomeJudgment $ query (AuthAgencyAct principal agent actId)
                   Set.empty
               ]
      combineVerdicts js `shouldBe` Valid

    it "someJudgmentSteps preserves reasoning chain" $ do
      let j = SomeJudgment $ query (MistakeAct person actId)
                (Set.singleton GrossNegligence)
          steps = someJudgmentSteps j
      length steps `shouldBe` 2
      stepKind (head steps) `shouldBe` Applied
      stepKind (last steps) `shouldBe` Overridden
