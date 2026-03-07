{-# LANGUAGE OverloadedStrings #-}
-- | Helper module loaded by ghci for generating case framework output.
-- Usage: cabal exec ghci -- -package deontic-kr-civil scripts/GenCaseOutput.hs
module GenCaseOutput where

import qualified Data.Set as Set
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.Time.Calendar (fromGregorian)

import Deontic.Core.Types (PersonId(..), ActId(..))
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate (SomeJudgment(..), verdict, combineVerdicts)
import Deontic.Render (Renderer(..))
import Deontic.Civil.Types
import Deontic.Civil.Evaluate
import Deontic.Civil.Render (KoreanRenderer(..), OutputFormat(..), Block(..), Inline(..), renderBlocks)

-- Bring instances into scope
import Deontic.Civil.Persons ()
import Deontic.Civil.Acts ()
import Deontic.Civil.Agency ()
import Deontic.Civil.Possession ()
import Deontic.Civil.Prescription ()
import Deontic.Civil.CoOwnership ()
import Deontic.Civil.Tort ()
import Deontic.Civil.Rescission ()
import Deontic.Civil.PropertyTransfer ()
import Deontic.Civil.AcquisitivePrescription ()
import Deontic.Civil.DefaultObligation ()
import Deontic.Civil.SaleWarranty ()
import Deontic.Civil.Lease ()
import Deontic.Civil.AgencyRemedies ()
import Deontic.Civil.Invalidity ()
import Deontic.Civil.Cancellation ()
import Deontic.Civil.ConditionalAct ()

-- | Build blocks for a single evaluation result.
resultBlocks :: CaseResult -> [Block]
resultBlocks (CaseResult label (SomeJudgment j)) =
  [ Heading 3 (Seq [ Bold (Plain label)
                    , Plain (" — " <> T.pack (show (verdict j)))
                    ])
  , Blank
  , Para (Plain (renderJudgment (KoreanRenderer Markdown) j))
  ]

-- | Build blocks for all results from a case.
resultsBlocks :: CaseFacts -> [Block]
resultsBlocks cf =
  let results = evaluateAll cf
  in if null results
     then [Para (Plain "(모든 쟁점에서 사안과 무관한 것으로 판단됨)")]
     else concatMap resultBlocks results
          ++ case results of
               [_] -> []
               _   -> [ Heading 4 (Plain "종합 판단")
                       , Para (Plain ("combineVerdicts = "
                               <> T.pack (show (combineVerdicts (map crJudgment results)))))
                       ]

-- | Print all results for a case as markdown.
printResults :: CaseFacts -> IO ()
printResults = TIO.putStr . renderBlocks Markdown . resultsBlocks
