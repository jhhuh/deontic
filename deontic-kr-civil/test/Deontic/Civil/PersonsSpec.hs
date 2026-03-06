{-# LANGUAGE OverloadedStrings #-}
module Deontic.Civil.PersonsSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types (MinorAct(..))
import Deontic.Civil.Persons ()

spec :: Spec
spec = do
  describe "민법 제5조 — 미성년자의 법률행위" $ do
    let minor = PersonId "김철수"
        guardian = PersonId "김부모"
        act1 = ActId "매매계약"

    it "§5① 본문: 동의 없이 한 법률행위는 취소할 수 있다" $ do
      let j = query (MinorAct minor act1)
                (Set.fromList [IsMinor minor, PerformsAct minor act1])
      verdict j `shouldBe` Voidable

    it "§5① 단서: 권리만을 얻는 법률행위는 유효하다" $ do
      let j = query (MinorAct minor act1)
                (Set.fromList [ IsMinor minor
                              , PerformsAct minor act1
                              , Custom "merely-acquires-right"
                              ])
      verdict j `shouldBe` Valid

    it "§5①: 법정대리인의 동의가 있으면 유효하다" $ do
      let j = query (MinorAct minor act1)
                (Set.fromList [ IsMinor minor
                              , PerformsAct minor act1
                              , HasConsent guardian act1
                              ])
      verdict j `shouldBe` Valid
