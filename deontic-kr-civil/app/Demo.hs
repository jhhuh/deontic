-- | Case demonstration runner.
-- Given only a set of confirmed facts, the framework runs ALL act types
-- and outputs judgments for every non-trivial result.
-- No human selection of act types — purely mechanical.
module Main where

import qualified Data.Set as Set
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.Time.Calendar (fromGregorian)
import System.IO (hSetEncoding, stdout, utf8)

import Deontic.Core.Types (PersonId(..), ActId(..))
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate (SomeJudgment(..), verdict, combineVerdicts)
import Deontic.Render (Renderer(..))
import Deontic.Civil.Types
import Deontic.Civil.Evaluate
import Deontic.Civil.Render (KoreanRenderer(..), OutputFormat(..))

main :: IO ()
main = do
  hSetEncoding stdout utf8

  runCase "Case 1: 미성년자의 신용구매 (대법원 2005다71659)"
    (defaultCaseFacts (PersonId "갑") (ActId "신용구매계약"))
      { cfCivilFacts = Set.singleton (IsMinor (PersonId "갑")) }

  runCase "Case 2: 통정허위표시 + 선의 제3자 (대법원 2019다280375)"
    (defaultCaseFacts (PersonId "채무자") (ActId "허위명의이전"))
      { cfCivilFacts = Set.singleton BonaFideThirdParty }

  runCase "Case 3: 착오 + 중대한 과실 (대법원 2013다49794)"
    (defaultCaseFacts (PersonId "매수인") (ActId "토지매매"))
      { cfCivilFacts = Set.singleton GrossNegligence }

  runCase "Case 4: 시효중단 (대법원 93다47745)"
    $ domainFact PrescriptionK PrescriptionFacts
          { pfClaimDate    = fromGregorian 2010 1 1
          , pfCurrentDate  = fromGregorian 2021 1 1
          , pfPeriodYears  = 10
          , pfInterruptedOn = Just (fromGregorian 2018 1 1)
          }
    $ defaultCaseFacts (PersonId "채권자") (ActId "대여금")

  runCase "Case 5: 교통사고 + 과실상계"
    $ domainFact TortK (TortFacts True True True True True)
    $ (defaultCaseFacts (PersonId "피해자") (ActId "교통사고"))
      { cfCounterparty = Just (PersonId "가해자") }

  runCase "Case 6: 복합 쟁점 — 미성년자 무권대리 사기매매"
    $ domainFact PrescriptionK PrescriptionFacts
          { pfClaimDate    = fromGregorian 2005 1 1
          , pfCurrentDate  = fromGregorian 2018 6 1
          , pfPeriodYears  = 10
          , pfInterruptedOn = Nothing
          }
    $ (defaultCaseFacts (PersonId "갑") (ActId "토지매매"))
      { cfCounterparty = Just (PersonId "을")
      , cfCivilFacts = Set.fromList
          [ IsMinor (PersonId "갑")
          , ThirdPartyFraud
          ]
      }

  runCase "Case 7: 제3자 사기 + 상대방 선의 (대법원 98다60828)"
    (defaultCaseFacts (PersonId "갑") (ActId "매매계약"))
      { cfCivilFacts = Set.singleton ThirdPartyFraud }

  runCase "Case 8: 무권대리 + 표현대리 (대법원 91다32190)"
    (defaultCaseFacts (PersonId "본인") (ActId "매매"))
      { cfCounterparty = Just (PersonId "대리인")
      , cfCivilFacts = Set.singleton ExceededScope
      }

  runCase "Case 9: 불공정 법률행위 (§104)"
    (defaultCaseFacts (PersonId "표의자") (ActId "고리대금"))
      { cfCivilFacts = Set.singleton ExploitativeAct }

  runCase "Case 10: 점유 추정 + 악의 반증"
    (defaultCaseFacts (PersonId "점유자") (ActId "부동산점유"))
      { cfCivilFacts = Set.singleton BadFaith }

runCase :: String -> CaseFacts -> IO ()
runCase title cf = do
  putStrLn ""
  putStrLn $ replicate 60 '═'
  putStrLn $ "  " ++ title
  putStrLn $ replicate 60 '═'
  putStrLn ""

  putStrLn "【입력: 확인된 사실】"
  putStrLn $ "  행위자: " ++ show (cfActor cf)
  putStrLn $ "  행위:   " ++ show (cfActId cf)
  case cfCounterparty cf of
    Just cp -> putStrLn $ "  상대방: " ++ show cp
    Nothing -> pure ()
  if Set.null (cfCivilFacts cf)
    then putStrLn "  사실관계: (없음)"
    else mapM_ (\f -> putStrLn $ "  • " ++ show f) (Set.toList (cfCivilFacts cf))
  putStrLn ""

  let results = evaluateAll cf
  if null results
    then putStrLn "  (모든 쟁점에서 사안과 무관한 것으로 판단됨)"
    else do
      putStrLn $ "【비자명 쟁점: " ++ show (length results) ++ "건】"
      putStrLn ""
      mapM_ printResult results

      when (length results > 1) $ do
        putStrLn "── 종합 판단 ──"
        let combined = combineVerdicts (map crJudgment results)
        putStrLn $ "  combineVerdicts = " ++ show combined
        putStrLn ""

when :: Bool -> IO () -> IO ()
when True  m = m
when False _ = pure ()

printResult :: CaseResult -> IO ()
printResult (CaseResult label (SomeJudgment j)) = do
  TIO.putStrLn $ "── " <> label <> " ── " <> T.pack (show (verdict j))
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)
