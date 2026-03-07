{-# LANGUAGE LambdaCase #-}
module Main where

import Control.Exception (catch)
import qualified Data.Set as Set
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.IO (hFlush, stdout, hSetEncoding, utf8)
import System.IO.Error (isEOFError)

import Data.Time.Calendar (fromGregorian)
import Deontic.Core.Types (PersonId(..), ActId(..))
import Deontic.Core.Verdict (Verdict(..))
import Deontic.Core.Adjudicate (query)
import Deontic.Render (Renderer(..))
import Deontic.Civil.Types
import Deontic.Civil.Persons ()
import Deontic.Civil.Acts ()
import Deontic.Civil.Agency ()
import Deontic.Civil.CoOwnership ()
import Deontic.Civil.Possession ()
import Deontic.Civil.Prescription ()
import Deontic.Civil.Tort ()
import Deontic.Civil.Render (KoreanRenderer(..), OutputFormat(..))

main :: IO ()
main = do
  hSetEncoding stdout utf8
  TIO.putStrLn "╔══════════════════════════════════════╗"
  TIO.putStrLn "║  민법 법률행위 판단기 (Civil Act)    ║"
  TIO.putStrLn "╚══════════════════════════════════════╝"
  TIO.putStrLn ""
  repl

repl :: IO ()
repl = do
  TIO.putStrLn "행위 유형을 선택하세요:"
  TIO.putStrLn "  1) 미성년자의 법률행위 (§5)"
  TIO.putStrLn "  2) 일반 법률행위 (§103-107)"
  TIO.putStrLn "  3) 통정허위표시 (§108)"
  TIO.putStrLn "  4) 착오에 의한 의사표시 (§109)"
  TIO.putStrLn "  5) 사기·강박에 의한 의사표시 (§110)"
  TIO.putStrLn "  6) 유권대리 (§114, §118)"
  TIO.putStrLn "  7) 무권대리 (§125-132)"
  TIO.putStrLn "  8) 점유 추정 (§197, §200)"
  TIO.putStrLn "  9) 소멸시효 (§162, §168, §174)"
  TIO.putStrLn "  10) 공유물의 처분 (§264)"
  TIO.putStrLn "  11) 불법행위 (§750, §396)"
  TIO.putStrLn "  q) 종료"
  TIO.putStr "> "
  hFlush stdout
  mLine <- (Just <$> getLine) `catch` \e ->
    if isEOFError e then pure Nothing else ioError e
  case mLine of
    Nothing  -> TIO.putStrLn "\n종료합니다."
    Just "q" -> TIO.putStrLn "종료합니다."
    Just "1" -> handleMinorAct >> repl
    Just "2" -> handleJuristicAct >> repl
    Just "3" -> handleShamAct >> repl
    Just "4" -> handleMistakeAct >> repl
    Just "5" -> handleFraudAct >> repl
    Just "6" -> handleAuthAgency >> repl
    Just "7" -> handleUnauthAgency >> repl
    Just "8" -> handlePossession >> repl
    Just "9" -> handlePrescription >> repl
    Just "10" -> handleCoOwnership >> repl
    Just "11" -> handleTort >> repl
    Just _   -> TIO.putStrLn "잘못된 입력입니다.\n" >> repl

askFacts :: [(String, CivilFact)] -> IO (Set.Set CivilFact)
askFacts options = do
  TIO.putStrLn "\n해당하는 사실관계를 선택하세요 (번호를 쉼표로 구분, 없으면 Enter):"
  mapM_ (\(i, (desc, _)) ->
    putStrLn $ "  " ++ show i ++ ") " ++ desc)
    (zip [1::Int ..] options)
  TIO.putStr "> "
  hFlush stdout
  input <- getLine
  let indices = parseIndices input
      facts = [f | (i, (_, f)) <- zip [1..] options, i `elem` indices]
  pure (Set.fromList facts)

parseIndices :: String -> [Int]
parseIndices = map read . filter (not . null) . map (filter (/= ' ')) . splitOn ','
  where
    splitOn _ [] = [""]
    splitOn c (x:xs)
      | x == c    = "" : splitOn c xs
      | otherwise  = let (h:t) = splitOn c xs in (x:h) : t

handleMinorAct :: IO ()
handleMinorAct = do
  let actor = PersonId "미성년자"
      actId = ActId "법률행위"
  facts <- askFacts
    [ ("법정대리인의 동의 있음", HasConsent (PersonId "법정대리인") actId)
    , ("권리만을 얻는 행위", MerelyAcquiresRight)
    ]
  let j = query (MinorAct actor actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)

handleJuristicAct :: IO ()
handleJuristicAct = do
  let actor = PersonId "표의자"
      actId = ActId "법률행위"
  facts <- askFacts
    [ ("진의 아닌 의사표시 (비진의)", HiddenIntention)
    , ("상대방이 진의 아님을 알았음", CounterpartyKnew)
    , ("선량한 풍속 위반 (반사회질서)", ContraBonorsMores)
    , ("불공정한 법률행위", ExploitativeAct)
    ]
  let j = query (JuristicAct actor actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)

handleShamAct :: IO ()
handleShamAct = do
  let actor = PersonId "표의자"
      actId = ActId "허위표시"
  facts <- askFacts
    [ ("선의의 제3자가 관여", BonaFideThirdParty)
    ]
  let j = query (ShamAct actor actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)

handleMistakeAct :: IO ()
handleMistakeAct = do
  let actor = PersonId "표의자"
      actId = ActId "착오행위"
  facts <- askFacts
    [ ("표의자의 중대한 과실", GrossNegligence)
    ]
  let j = query (MistakeAct actor actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)

handleFraudAct :: IO ()
handleFraudAct = do
  let actor = PersonId "피해자"
      actId = ActId "사기행위"
  facts <- askFacts
    [ ("제3자에 의한 사기", ThirdPartyFraud)
    , ("상대방이 제3자 사기 사실을 알았음", CounterpartyKnewFraud)
    ]
  let j = query (FraudAct actor actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)

handleAuthAgency :: IO ()
handleAuthAgency = do
  let principal = PersonId "본인"
      agent = PersonId "대리인"
      actId = ActId "대리행위"
  facts <- askFacts
    [ ("자기계약 또는 쌍방대리", SelfDealing)
    ]
  let j = query (AuthAgencyAct principal agent actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)

handleUnauthAgency :: IO ()
handleUnauthAgency = do
  let principal = PersonId "본인"
      agent = PersonId "무권대리인"
      actId = ActId "무권대리행위"
  facts <- askFacts
    [ ("본인이 추인함", Ratified)
    , ("대리권수여의 표시 있음 (§125)", IndicatedAuthority)
    , ("권한을 넘었으나 정당한 사유 (§126)", ExceededScope)
    , ("대리권 소멸 후 선의의 제3자 (§129)", AuthorityExpired)
    ]
  let j = query (UnauthAgencyAct principal agent actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)

handlePossession :: IO ()
handlePossession = do
  let actor = PersonId "점유자"
      actId = ActId "점유"
  facts <- askFacts
    [ ("악의 점유 (§197 반증)", BadFaith)
    , ("강폭 점유 (§197 반증)", ViolentPossession)
    , ("은비 점유 (§197 반증)", ClandestinePossession)
    , ("타주점유 (§200 반증)", NoOwnershipIntent)
    ]
  let j = query (PossessionAct actor actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)

handlePrescription :: IO ()
handlePrescription = do
  let creditor = PersonId "채권자"
      claimId  = ActId "대여금채권"
  TIO.putStr "\n소멸시효기간 (년): "
  hFlush stdout
  periodYears <- readLn :: IO Int
  TIO.putStr "채권 발생 연도 (예: 2015): "
  hFlush stdout
  claimYear <- readLn :: IO Integer
  TIO.putStr "채권 발생 월 (1-12): "
  hFlush stdout
  claimMonth <- readLn :: IO Int
  TIO.putStr "채권 발생 일 (1-31): "
  hFlush stdout
  claimDay <- readLn :: IO Int
  TIO.putStr "판단 시점 연도 (예: 2026): "
  hFlush stdout
  curYear <- readLn :: IO Integer
  TIO.putStr "판단 시점 월 (1-12): "
  hFlush stdout
  curMonth <- readLn :: IO Int
  TIO.putStr "판단 시점 일 (1-31): "
  hFlush stdout
  curDay <- readLn :: IO Int
  TIO.putStr "시효중단 여부 (y/n): "
  hFlush stdout
  interrupted <- getLine
  intDate <- case interrupted of
    "y" -> do
      TIO.putStr "중단 시점 연도: "
      hFlush stdout
      iy <- readLn :: IO Integer
      TIO.putStr "중단 시점 월: "
      hFlush stdout
      im <- readLn :: IO Int
      TIO.putStr "중단 시점 일: "
      hFlush stdout
      iday <- readLn :: IO Int
      pure (Just (fromGregorian iy im iday))
    _   -> pure Nothing
  let facts = PrescriptionFacts
        { pfClaimDate   = fromGregorian claimYear claimMonth claimDay
        , pfCurrentDate = fromGregorian curYear curMonth curDay
        , pfPeriodYears = periodYears
        , pfInterruptedOn = intDate
        }
      j = query (PrescriptionAct creditor claimId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)

handleCoOwnership :: IO ()
handleCoOwnership = do
  let actId = ActId "토지처분"
  TIO.putStr "\n공유자 수: "
  hFlush stdout
  n <- readLn :: IO Int
  let owners = [PersonId (T.pack ("공유자" ++ show i)) | i <- [1..n]]
  TIO.putStrLn "동의한 공유자 번호를 쉼표로 구분 (없으면 Enter):"
  mapM_ (\(i, PersonId name) ->
    TIO.putStrLn ("  " <> T.pack (show i) <> ") " <> name))
    (zip [1::Int ..] owners)
  TIO.putStr "> "
  hFlush stdout
  input <- getLine
  let indices = parseIndices input
      consented = Set.fromList [o | (i, o) <- zip [1..] owners, i `elem` indices]
      facts = CoOwnershipFacts { cofOwners = owners, cofConsented = consented }
      j = query (CoOwnershipAct actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)

handleTort :: IO ()
handleTort = do
  let victim     = PersonId "피해자"
      tortfeasor = PersonId "가해자"
      actId      = ActId "사고"
  TIO.putStrLn "\n불법행위 요건 (y/n):"
  let askYN prompt = do
        TIO.putStr prompt
        hFlush stdout
        ans <- getLine
        pure (ans == "y")
  fault     <- askYN "  고의 또는 과실? "
  unlawful  <- askYN "  위법성? "
  damage    <- askYN "  손해 발생? "
  causation <- askYN "  인과관계? "
  victimNeg <- askYN "  피해자 과실 (과실상계)? "
  let facts = TortFacts fault unlawful damage causation victimNeg
      j = query (TortAct victim tortfeasor actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment (KoreanRenderer PlainText) j)
