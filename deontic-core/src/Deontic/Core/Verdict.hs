module Deontic.Core.Verdict
  ( Verdict(..)
  , verdictMeet
  ) where

data Verdict = Valid | Void | Voidable
  deriving (Eq, Ord, Show)

-- | Combine independent verdicts: Void > Voidable > Valid
verdictMeet :: Verdict -> Verdict -> Verdict
verdictMeet Void _ = Void
verdictMeet _ Void = Void
verdictMeet Voidable _ = Voidable
verdictMeet _ Voidable = Voidable
verdictMeet Valid Valid = Valid
