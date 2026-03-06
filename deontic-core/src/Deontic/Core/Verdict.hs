module Deontic.Core.Verdict
  ( Verdict(..)
  , verdictMeet
  ) where

data Verdict = Valid | Void | Voidable | Pending
  deriving (Eq, Ord, Show)

-- | Combine independent verdicts: Void > Pending > Voidable > Valid
verdictMeet :: Verdict -> Verdict -> Verdict
verdictMeet Void _ = Void
verdictMeet _ Void = Void
verdictMeet Pending _ = Pending
verdictMeet _ Pending = Pending
verdictMeet Voidable _ = Voidable
verdictMeet _ Voidable = Voidable
verdictMeet Valid Valid = Valid
