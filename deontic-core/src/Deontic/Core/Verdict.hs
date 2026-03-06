-- | Legal verdicts and their algebra.
--
-- 'Verdict' forms a bounded semilattice under 'verdictMeet'
-- with 'Valid' as identity and 'Void' as absorbing element.
-- The ordering @Void > Pending > Voidable > Valid@ reflects
-- legal severity.
module Deontic.Core.Verdict
  ( Verdict(..)
  , verdictMeet
  ) where

-- | The four possible verdicts for a legal act.
data Verdict
  = Valid     -- ^ 유효 — the act is fully effective
  | Void      -- ^ 무효 — the act has no legal effect
  | Voidable  -- ^ 취소가능 — the act is effective but may be rescinded
  | Pending   -- ^ 효력미정 — effectiveness depends on a future event
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
