module Deontic.Core.Adjudicate
  ( Adjudicate(..)
  , Judgment(..)
  , verdict
  , query
  ) where

import Data.Kind (Type)
import Data.Text (Text)
import GHC.TypeLits (TypeError, ErrorMessage(..))
import Deontic.Core.Types (ArticleRef, Facts)
import Deontic.Core.Verdict (Verdict)
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

-- | Extract the final verdict from any judgment
verdict :: Judgment layers -> Verdict
verdict (JBase v _ _)        = v
verdict (JOverride _ v _ _)  = v
verdict (JDelegate prev)     = verdict prev

-- | Core typeclass: stratified adjudication
class Adjudicate act (layers :: [Type]) where
  adjudicate :: act -> Facts -> Judgment layers

-- | Non-resolution: empty layer stack is a type error (법의 흠결)
instance TypeError
    ( 'Text "법의 흠결 (lacuna): no applicable rule for "
      ':<>: 'ShowType act
    ) => Adjudicate act '[] where
  adjudicate = error "unreachable"

-- | Top-level query using Resolvable to determine the layer stack
query :: forall act. Adjudicate act (Resolvable act) => act -> Facts -> Judgment (Resolvable act)
query act facts = adjudicate act facts
