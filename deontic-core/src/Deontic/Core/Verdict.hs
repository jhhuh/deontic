module Deontic.Core.Verdict
  ( Verdict(..)
  ) where

data Verdict = Valid | Void | Voidable
  deriving (Eq, Ord, Show)
