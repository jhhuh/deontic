module Deontic.Civil.AgencySpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types
import Deontic.Civil.Agency ()

spec :: Spec
spec = do
  describe "민법 유권대리 (§114, §118)" $ do
    let principal = PersonId "본인"
        agent = PersonId "대리인"
        act1 = ActId "매매계약"

    it "§114: 유권대리는 본인에게 효력이 생긴다 (유효)" $ do
      let j = query (AuthAgencyAct principal agent act1) Set.empty
      verdict j `shouldBe` Valid

    it "§118: 자기계약은 취소할 수 있다" $ do
      let j = query (AuthAgencyAct principal agent act1)
                (Set.singleton SelfDealing)
      verdict j `shouldBe` Voidable

  describe "민법 무권대리 (§130, §132, §125-129)" $ do
    let principal = PersonId "본인"
        agent = PersonId "무권대리인"
        act1 = ActId "계약"

    it "§130: 무권대리는 효력미정" $ do
      let j = query (UnauthAgencyAct principal agent act1) Set.empty
      verdict j `shouldBe` Pending

    it "§132: 추인하면 유효" $ do
      let j = query (UnauthAgencyAct principal agent act1)
                (Set.singleton Ratified)
      verdict j `shouldBe` Valid

    it "§125: 대리권수여 표시가 있으면 유효 (표현대리)" $ do
      let j = query (UnauthAgencyAct principal agent act1)
                (Set.singleton IndicatedAuthority)
      verdict j `shouldBe` Valid

    it "§126: 권한을 넘었으나 정당한 사유가 있으면 유효" $ do
      let j = query (UnauthAgencyAct principal agent act1)
                (Set.singleton ExceededScope)
      verdict j `shouldBe` Valid

    it "§129: 대리권 소멸 후 선의의 제3자에게 유효" $ do
      let j = query (UnauthAgencyAct principal agent act1)
                (Set.singleton AuthorityExpired)
      verdict j `shouldBe` Valid

    it "추인도 표현대리도 없으면 효력미정" $ do
      let j = query (UnauthAgencyAct principal agent act1)
                (Set.singleton BonaFideThirdParty)  -- irrelevant fact
      verdict j `shouldBe` Pending
