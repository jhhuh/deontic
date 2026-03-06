module Deontic.Civil.ActsSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types (JuristicAct(..), ShamAct(..), MistakeAct(..), FraudAct(..), CivilFact(..))
import Deontic.Civil.Acts ()

spec :: Spec
spec = do
  describe "민법 법률행위" $ do
    let person = PersonId "이영희"
        act1 = ActId "계약"

    it "§103: 반사회질서의 법률행위는 무효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [ContraBonorsMores])
      verdict j `shouldBe` Void

    it "§104: 불공정한 법률행위는 무효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [ExploitativeAct])
      verdict j `shouldBe` Void

    it "§107①: 비진의 의사표시는 유효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [HiddenIntention])
      verdict j `shouldBe` Valid

    it "§107②: 상대방이 안 경우 무효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [HiddenIntention, CounterpartyKnew])
      verdict j `shouldBe` Void

  describe "민법 제108조 — 통정허위표시" $ do
    let person = PersonId "박민수"
        act1 = ActId "가장매매"

    it "§108①: 통정허위표시는 무효" $ do
      let j = query (ShamAct person act1) Set.empty
      verdict j `shouldBe` Void

    it "§108②: 선의의 제3자에게는 대항 불가 (유효)" $ do
      let j = query (ShamAct person act1)
                (Set.singleton BonaFideThirdParty)
      verdict j `shouldBe` Valid

  describe "민법 제109조 — 착오로 인한 의사표시" $ do
    let person = PersonId "최수진"
        act1 = ActId "착오계약"

    it "§109① 본문: 중요부분 착오 시 취소 가능" $ do
      let j = query (MistakeAct person act1) Set.empty
      verdict j `shouldBe` Voidable

    it "§109① 단서: 중과실이면 취소 불가 (유효)" $ do
      let j = query (MistakeAct person act1)
                (Set.singleton GrossNegligence)
      verdict j `shouldBe` Valid

  describe "민법 제110조 — 사기·강박에 의한 의사표시" $ do
    let person = PersonId "정호영"
        act1 = ActId "사기계약"

    it "§110①: 사기·강박에 의한 의사표시는 취소 가능" $ do
      let j = query (FraudAct person act1) Set.empty
      verdict j `shouldBe` Voidable

    it "§110②: 제3자 사기, 상대방 악의 → 취소 가능" $ do
      let j = query (FraudAct person act1)
                (Set.fromList [ThirdPartyFraud, CounterpartyKnewFraud])
      verdict j `shouldBe` Voidable

    it "§110②: 제3자 사기, 상대방 선의 → 취소 불가 (유효)" $ do
      let j = query (FraudAct person act1)
                (Set.singleton ThirdPartyFraud)
      verdict j `shouldBe` Valid

  describe "verdictMeet — 독립된 판단 결합" $ do
    it "Void ∧ Voidable = Void" $
      verdictMeet Void Voidable `shouldBe` Void
    it "Voidable ∧ Valid = Voidable" $
      verdictMeet Voidable Valid `shouldBe` Voidable
    it "Valid ∧ Valid = Valid" $
      verdictMeet Valid Valid `shouldBe` Valid
