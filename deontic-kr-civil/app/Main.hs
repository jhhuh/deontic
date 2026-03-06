{-# LANGUAGE LambdaCase #-}
module Main where

import Control.Exception (catch)
import qualified Data.Set as Set
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.IO (hFlush, stdout, hSetEncoding, utf8)
import System.IO.Error (isEOFError)

import Deontic.Core.Types (PersonId(..), ActId(..))
import Deontic.Core.Verdict (verdictMeet, Verdict(..))
import Deontic.Core.Adjudicate (query)
import Deontic.Render (Renderer(..))
import Deontic.Civil.Types
import Deontic.Civil.Persons ()
import Deontic.Civil.Acts ()
import Deontic.Civil.Agency ()
import Deontic.Civil.Render (KoreanRenderer(..))

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
  TIO.putStrLn (renderJudgment KoreanRenderer j)

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
  TIO.putStrLn (renderJudgment KoreanRenderer j)

handleShamAct :: IO ()
handleShamAct = do
  let actor = PersonId "표의자"
      actId = ActId "허위표시"
  facts <- askFacts
    [ ("선의의 제3자가 관여", BonaFideThirdParty)
    ]
  let j = query (ShamAct actor actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment KoreanRenderer j)

handleMistakeAct :: IO ()
handleMistakeAct = do
  let actor = PersonId "표의자"
      actId = ActId "착오행위"
  facts <- askFacts
    [ ("표의자의 중대한 과실", GrossNegligence)
    ]
  let j = query (MistakeAct actor actId) facts
  TIO.putStrLn ""
  TIO.putStrLn (renderJudgment KoreanRenderer j)

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
  TIO.putStrLn (renderJudgment KoreanRenderer j)

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
  TIO.putStrLn (renderJudgment KoreanRenderer j)

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
  TIO.putStrLn (renderJudgment KoreanRenderer j)
