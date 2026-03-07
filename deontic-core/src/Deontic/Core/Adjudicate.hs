-- | Core adjudication engine: stratified defeasible reasoning.
--
-- The 'Adjudicate' typeclass resolves legal rules via GHC's instance
-- resolution. The 'Judgment' GADT carries the full reasoning chain
-- as a proof term.
module Deontic.Core.Adjudicate
  ( Adjudicate(..)
  , Judgment(..)
  , verdict
  , query
  , SomeJudgment(..)
  , someVerdict
  , combineVerdicts
  ) where

import Data.Kind (Type)
import Data.Text (Text)
import GHC.TypeLits (TypeError, ErrorMessage(..))
import Deontic.Core.Types (ArticleRef, Facts)
import Data.List (foldl')
import Deontic.Core.Verdict (Verdict(..), verdictMeet)
import Deontic.Core.Layer (Resolvable)

-- | Judgment GADT — carries the full reasoning chain in its type
data Judgment (layers :: [Type]) where
  -- | Direct rule application (bottom layer — any layer token)
  JBase     :: Verdict -> ArticleRef -> Text
            -> Judgment '[l]
  -- | This layer overrides the verdict from a lower layer
  JOverride :: Judgment prev -> Verdict -> ArticleRef -> Text
            -> Judgment (l ': prev)
  -- | This layer was available but delegated (did not override)
  JDelegate :: Judgment prev
            -> Judgment (l ': prev)
  -- | Counterfactual: §150-style "deemed fulfilled/unfulfilled"
  --   Carries the hypothetical reasoning chain as a SomeJudgment
  JCounterfactual :: Judgment prev -> SomeJudgment -> Verdict -> ArticleRef -> Text
                  -> Judgment (l ': prev)

-- | Extract the final verdict from any judgment
verdict :: Judgment layers -> Verdict
verdict (JBase v _ _)                = v
verdict (JOverride _ v _ _)          = v
verdict (JDelegate prev)             = verdict prev
verdict (JCounterfactual _ _ v _ _)  = v

-- | Core typeclass: stratified adjudication
class Adjudicate act (layers :: [Type]) where
  adjudicate :: act -> Facts act -> Judgment layers

-- | Non-resolution: empty layer stack is a type error (법의 흠결)
instance TypeError
    ( 'Text "법의 흠결 (lacuna): no applicable rule for "
      ':<>: 'ShowType act
    ) => Adjudicate act '[] where
  adjudicate = error "unreachable"

-- | Top-level query using Resolvable to determine the layer stack
query :: forall act. Adjudicate act (Resolvable act) => act -> Facts act -> Judgment (Resolvable act)
query act facts = adjudicate act facts

-- | Existential wrapper — hides the layer type for heterogeneous collections
data SomeJudgment where
  SomeJudgment :: Judgment layers -> SomeJudgment

-- | Extract verdict from an existentially-wrapped judgment
someVerdict :: SomeJudgment -> Verdict
someVerdict (SomeJudgment j) = verdict j

-- | Combine independent judgments: fold verdicts with meet
combineVerdicts :: [SomeJudgment] -> Verdict
combineVerdicts = foldl' (\acc sj -> verdictMeet acc (someVerdict sj)) Valid
