-- Formal verification sketch: Curry-Howard for Defeasible Deontic Logic
--
-- This is a minimal Agda encoding of the core framework to prove
-- that verdict extraction from the Judgment GADT is total.
-- It does NOT require Agda to be installed — it serves as a
-- specification that could be type-checked if desired.

module Deontic where

open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ═══════════════════════════════════════════════
-- Core Types
-- ═══════════════════════════════════════════════

data Verdict : Set where
  Valid    : Verdict
  Void     : Verdict
  Voidable : Verdict
  Pending  : Verdict

-- Verdict meet (semilattice operation)
_⊓_ : Verdict → Verdict → Verdict
Void     ⊓ _        = Void
_        ⊓ Void     = Void
Pending  ⊓ _        = Pending
_        ⊓ Pending  = Pending
Voidable ⊓ _        = Voidable
_        ⊓ Voidable = Voidable
Valid    ⊓ Valid     = Valid

-- Layer is any type (open, like Haskell's uninhabited types)
Layer : Set₁
Layer = Set

-- ═══════════════════════════════════════════════
-- Judgment GADT
-- ═══════════════════════════════════════════════

-- ArticleRef simplified to a natural number
open import Data.Nat using (ℕ)
open import Data.String using (String)

record ArticleRef : Set where
  constructor mkRef
  field
    article : ℕ

data Judgment : List Layer → Set₁ where
  JBase     : ∀ {l} →
              Verdict → ArticleRef → String →
              Judgment (l ∷ [])

  JOverride : ∀ {l prev} →
              Judgment prev → Verdict → ArticleRef → String →
              Judgment (l ∷ prev)

  JDelegate : ∀ {l prev} →
              Judgment prev →
              Judgment (l ∷ prev)

-- ═══════════════════════════════════════════════
-- Verdict extraction — TOTAL
-- ═══════════════════════════════════════════════

verdict : ∀ {layers} → Judgment layers → Verdict
verdict (JBase v _ _)        = v
verdict (JOverride _ v _ _)  = v
verdict (JDelegate prev)     = verdict prev

-- ═══════════════════════════════════════════════
-- Proof: verdict extraction is total
--
-- In Agda, totality is checked by the type checker.
-- The fact that `verdict` type-checks without any
-- absurd patterns or postulates means it is total
-- over all possible Judgment values.
--
-- Key insight: the empty list case '[]' is impossible
-- because all three constructors require at least one
-- layer (l ∷ [] or l ∷ prev). This mirrors the Haskell
-- TypeError for Adjudicate act '[] — gaps are prevented
-- by construction.
-- ═══════════════════════════════════════════════

-- ═══════════════════════════════════════════════
-- Proof: verdictMeet properties
-- ═══════════════════════════════════════════════

-- Identity: Valid ⊓ a ≡ a
meet-identity-left : ∀ (a : Verdict) → Valid ⊓ a ≡ a
meet-identity-left Valid    = refl
meet-identity-left Void     = refl
meet-identity-left Voidable = refl
meet-identity-left Pending  = refl

-- Absorbing: Void ⊓ a ≡ Void
meet-absorbing-left : ∀ (a : Verdict) → Void ⊓ a ≡ Void
meet-absorbing-left Valid    = refl
meet-absorbing-left Void     = refl
meet-absorbing-left Voidable = refl
meet-absorbing-left Pending  = refl

-- Commutativity: a ⊓ b ≡ b ⊓ a
meet-comm : ∀ (a b : Verdict) → a ⊓ b ≡ b ⊓ a
meet-comm Valid    Valid    = refl
meet-comm Valid    Void     = refl
meet-comm Valid    Voidable = refl
meet-comm Valid    Pending  = refl
meet-comm Void     Valid    = refl
meet-comm Void     Void     = refl
meet-comm Void     Voidable = refl
meet-comm Void     Pending  = refl
meet-comm Voidable Valid    = refl
meet-comm Voidable Void     = refl
meet-comm Voidable Voidable = refl
meet-comm Voidable Pending  = refl
meet-comm Pending  Valid    = refl
meet-comm Pending  Void     = refl
meet-comm Pending  Voidable = refl
meet-comm Pending  Pending  = refl

-- ═══════════════════════════════════════════════
-- Example: a simple act type (MinorAct analogue)
-- ═══════════════════════════════════════════════

-- Layer tokens
data Base : Set where
data Proviso : Set where

-- A concrete judgment: minor without consent (Voidable base)
-- overridden by purely-acquires-right proviso (Valid)
exampleJudgment : Judgment (Proviso ∷ Base ∷ [])
exampleJudgment =
  JOverride
    (JBase Voidable (mkRef 5) "consent required")
    Valid
    (mkRef 5)
    "merely acquires right"

-- Proof that the example verdict is Valid
exampleIsValid : verdict exampleJudgment ≡ Valid
exampleIsValid = refl
