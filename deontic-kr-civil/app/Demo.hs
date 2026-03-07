{-# LANGUAGE LambdaCase #-}
-- | Case demonstration runner.
-- Renders framework judgments for real 대법원 cases.
-- Output used in docs/civil-act/case-demonstrations.md
module Main where

import qualified Data.Set as Set
import qualified Data.Text.IO as TIO
import Data.Time.Calendar (fromGregorian)

import Deontic.Core.Types (PersonId(..), ActId(..))
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Persons ()
import Deontic.Civil.Acts ()
import Deontic.Civil.Agency ()
import Deontic.Civil.Possession ()
import Deontic.Civil.Prescription ()
import Deontic.Civil.Tort ()
import Deontic.Civil.Rescission ()
import Deontic.Civil.AgencyRemedies ()
import Deontic.Civil.Invalidity ()
import Deontic.Civil.Cancellation ()
import Deontic.Civil.ConditionalAct ()
import Deontic.Civil.Render (KoreanRenderer(..))

main :: IO ()
main = do
  separator "Case 1: 미성년자의 신용구매 (대법원 2005다71659)"
  case1_minor

  separator "Case 2a: 통정허위표시 — 당사자 간 (대법원 94다12074)"
  case2a_sham

  separator "Case 2b: 통정허위표시 — 선의 제3자 (대법원 2019다280375)"
  case2b_sham_thirdparty

  separator "Case 3: 착오 + 중대한 과실 (대법원 2013다49794)"
  case3_mistake

  separator "Case 4: 시효중단 (대법원 93다47745)"
  case4_prescription

  separator "Case 5: 교통사고 + 과실상계"
  case5_tort

  separator "Case 6: 복합 쟁점 — 미성년자 무권대리 사기매매"
  case6_composite

  separator "Case 7: 제3자 사기 + 상대방 선의 (대법원 98다60828)"
  case7_thirdparty_fraud

separator :: String -> IO ()
separator title = do
  putStrLn ""
  putStrLn $ replicate 60 '═'
  putStrLn $ "  " ++ title
  putStrLn $ replicate 60 '═'
  putStrLn ""

printFacts :: String -> IO ()
printFacts s = putStrLn $ "【사실관계】" ++ s

printRendered :: String -> IO ()
printRendered label = putStrLn $ "【" ++ label ++ "】"

-- ═══════════════════════════════════════════════════
-- Case 1: 미성년자의 신용구매 (대법원 2005다71659)
-- ═══════════════════════════════════════════════════

case1_minor :: IO ()
case1_minor = do
  let 갑 = PersonId "갑"
      actId = ActId "신용구매계약"
      facts = Set.singleton (IsMinor 갑)
      j = query (MinorAct 갑 actId) facts

  putStrLn "【인정사실】"
  putStrLn "  1. 갑(17세)은 미성년자이다."
  putStrLn "  2. 갑은 법정대리인의 동의 없이 신용구매계약을 체결하였다."
  putStrLn ""
  putStrLn "【Fact Mapping】"
  putStrLn "  IsMinor (PersonId \"갑\")  ← 인정사실 1"
  putStrLn "  HasConsent 부재            ← 인정사실 2"
  putStrLn ""
  putStrLn $ "【Verdict】 " ++ show (verdict j)
  putStrLn ""
  putStrLn "【프레임워크 판결문】"
  TIO.putStrLn (renderJudgment KoreanRenderer j)

-- ═══════════════════════════════════════════════════
-- Case 2a: 통정허위표시 — 당사자 간
-- ═══════════════════════════════════════════════════

case2a_sham :: IO ()
case2a_sham = do
  let 채무자 = PersonId "채무자"
      actId = ActId "허위명의이전"
      j = query (ShamAct 채무자 actId) Set.empty

  putStrLn "【인정사실】"
  putStrLn "  1. 채무자 갑은 강제집행 면탈 목적으로 부동산을 허위 이전하였다."
  putStrLn ""
  putStrLn "【Fact Mapping】"
  putStrLn "  ShamAct (act type 자체)    ← 인정사실 1"
  putStrLn "  BonaFideThirdParty 부재    ← 당사자 간의 문제"
  putStrLn ""
  putStrLn $ "【Verdict】 " ++ show (verdict j)
  putStrLn ""
  putStrLn "【프레임워크 판결문】"
  TIO.putStrLn (renderJudgment KoreanRenderer j)

-- ═══════════════════════════════════════════════════
-- Case 2b: 통정허위표시 — 선의 제3자
-- ═══════════════════════════════════════════════════

case2b_sham_thirdparty :: IO ()
case2b_sham_thirdparty = do
  let 채무자 = PersonId "채무자"
      actId = ActId "허위명의이전"
      facts = Set.singleton BonaFideThirdParty
      j = query (ShamAct 채무자 actId) facts

  putStrLn "【인정사실】"
  putStrLn "  1. 채무자 갑은 부동산을 허위로 을에게 이전하였다."
  putStrLn "  2. 병은 을로부터 선의로 매수하였다."
  putStrLn ""
  putStrLn "【Fact Mapping】"
  putStrLn "  ShamAct (act type)          ← 인정사실 1"
  putStrLn "  BonaFideThirdParty          ← 인정사실 2"
  putStrLn ""
  putStrLn $ "【Verdict】 " ++ show (verdict j)
  putStrLn ""
  putStrLn "【프레임워크 판결문】"
  TIO.putStrLn (renderJudgment KoreanRenderer j)

-- ═══════════════════════════════════════════════════
-- Case 3: 착오 + 중대한 과실
-- ═══════════════════════════════════════════════════

case3_mistake :: IO ()
case3_mistake = do
  let 매수인 = PersonId "매수인"
      actId = ActId "토지매매"
      facts = Set.singleton GrossNegligence
      j = query (MistakeAct 매수인 actId) facts

  putStrLn "【인정사실】"
  putStrLn "  1. 매수인 갑은 토지 면적에 관하여 착오가 있었다."
  putStrLn "  2. 갑에게 중대한 과실이 있다."
  putStrLn ""
  putStrLn "【Fact Mapping】"
  putStrLn "  MistakeAct (act type)       ← 인정사실 1"
  putStrLn "  GrossNegligence             ← 인정사실 2"
  putStrLn ""
  putStrLn $ "【Verdict】 " ++ show (verdict j)
  putStrLn ""
  putStrLn "【프레임워크 판결문】"
  TIO.putStrLn (renderJudgment KoreanRenderer j)

-- ═══════════════════════════════════════════════════
-- Case 4: 시효중단
-- ═══════════════════════════════════════════════════

case4_prescription :: IO ()
case4_prescription = do
  let 채권자 = PersonId "채권자"
      actId = ActId "대여금"
      facts = PrescriptionFacts
        { pfClaimDate    = fromGregorian 2010 1 1
        , pfCurrentDate  = fromGregorian 2021 1 1
        , pfPeriodYears  = 10
        , pfInterruptedOn = Just (fromGregorian 2018 1 1)
        }
      j = query (PrescriptionAct 채권자 actId) facts

  putStrLn "【인정사실】"
  putStrLn "  1. 채권 발생일: 2010-01-01"
  putStrLn "  2. 소멸시효: 10년"
  putStrLn "  3. 2018-01-01 채무자 일부 변제 (시효중단)"
  putStrLn "  4. 2021-01-01 소 제기"
  putStrLn ""
  putStrLn "【Fact Mapping】"
  putStrLn "  pfClaimDate    = 2010-01-01  ← 인정사실 1"
  putStrLn "  pfPeriodYears  = 10          ← 인정사실 2"
  putStrLn "  pfInterruptedOn = 2018-01-01 ← 인정사실 3"
  putStrLn "  pfCurrentDate  = 2021-01-01  ← 인정사실 4"
  putStrLn ""
  putStrLn $ "【Verdict】 " ++ show (verdict j)
  putStrLn ""
  putStrLn "【프레임워크 판결문】"
  TIO.putStrLn (renderJudgment KoreanRenderer j)

-- ═══════════════════════════════════════════════════
-- Case 5: 교통사고 + 과실상계
-- ═══════════════════════════════════════════════════

case5_tort :: IO ()
case5_tort = do
  let 피해자 = PersonId "피해자"
      가해자 = PersonId "가해자"
      actId = ActId "교통사고"
      facts = TortFacts True True True True True
      j = query (TortAct 피해자 가해자 actId) facts

  putStrLn "【인정사실】"
  putStrLn "  1. 가해자에게 과실 있음"
  putStrLn "  2. 위법성 인정"
  putStrLn "  3. 피해자에게 손해 발생"
  putStrLn "  4. 인과관계 인정"
  putStrLn "  5. 피해자에게도 과실 있음 (신호위반 보행)"
  putStrLn ""
  putStrLn "【Fact Mapping】"
  putStrLn "  TortFacts True True True True True"
  putStrLn "  (4요건 충족 + 피해자 과실)"
  putStrLn ""
  putStrLn $ "【Verdict】 " ++ show (verdict j)
  putStrLn ""
  putStrLn "【프레임워크 판결문】"
  TIO.putStrLn (renderJudgment KoreanRenderer j)

-- ═══════════════════════════════════════════════════
-- Case 6: 복합 쟁점
-- ═══════════════════════════════════════════════════

case6_composite :: IO ()
case6_composite = do
  let 갑 = PersonId "갑"
      을 = PersonId "을"
      병 = PersonId "병"
      actId = ActId "토지매매"

  let minorJ = query (MinorAct 갑 actId)
                     (Set.singleton (IsMinor 갑))
      agencyJ = query (UnauthAgencyAct 갑 을 actId)
                      Set.empty
      fraudJ = query (FraudAct 병 actId)
                     Set.empty
      prescJ = query (PrescriptionAct 병 actId)
                     (PrescriptionFacts
                       (fromGregorian 2005 1 1)
                       (fromGregorian 2018 6 1)
                       10
                       Nothing)

  putStrLn "【인정사실】"
  putStrLn "  1. 갑(17세)은 미성년 토지 소유자"
  putStrLn "  2. 을은 대리권 없이 갑의 토지를 병에게 매도 (사칭)"
  putStrLn "  3. 갑은 추인하지 않음"
  putStrLn "  4. 을의 행위는 사기에 해당"
  putStrLn "  5. 법률행위일 2005-01-01, 소 제기 2018-06-01 (13년 경과)"
  putStrLn ""

  putStrLn "── 쟁점 1: §5 미성년자 ──"
  putStrLn $ "  Verdict: " ++ show (verdict minorJ)
  TIO.putStrLn (renderJudgment KoreanRenderer minorJ)

  putStrLn "── 쟁점 2: §130 무권대리 ──"
  putStrLn $ "  Verdict: " ++ show (verdict agencyJ)
  TIO.putStrLn (renderJudgment KoreanRenderer agencyJ)

  putStrLn "── 쟁점 3: §110 사기 ──"
  putStrLn $ "  Verdict: " ++ show (verdict fraudJ)
  TIO.putStrLn (renderJudgment KoreanRenderer fraudJ)

  putStrLn "── 쟁점 4: §162 소멸시효 ──"
  putStrLn $ "  Verdict: " ++ show (verdict prescJ)
  TIO.putStrLn (renderJudgment KoreanRenderer prescJ)

  let allJ = [ SomeJudgment minorJ
             , SomeJudgment agencyJ
             , SomeJudgment fraudJ
             , SomeJudgment prescJ
             ]
  putStrLn "── 종합 판단 ──"
  putStrLn $ "  combineVerdicts = " ++ show (combineVerdicts allJ)

-- ═══════════════════════════════════════════════════
-- Case 7: 제3자 사기 + 상대방 선의
-- ═══════════════════════════════════════════════════

case7_thirdparty_fraud :: IO ()
case7_thirdparty_fraud = do
  let 피해자 = PersonId "갑"
      actId = ActId "매매계약"
      facts = Set.singleton ThirdPartyFraud
      j = query (FraudAct 피해자 actId) facts

  putStrLn "【인정사실】"
  putStrLn "  1. 을(제3자)이 갑을 기망하여 갑이 병과 매매계약을 체결"
  putStrLn "  2. 병은 을의 사기 사실을 알지 못함 (선의)"
  putStrLn ""
  putStrLn "【Fact Mapping】"
  putStrLn "  ThirdPartyFraud             ← 인정사실 1"
  putStrLn "  CounterpartyKnewFraud 부재  ← 인정사실 2"
  putStrLn ""
  putStrLn $ "【Verdict】 " ++ show (verdict j)
  putStrLn ""
  putStrLn "【프레임워크 판결문】"
  TIO.putStrLn (renderJudgment KoreanRenderer j)
