module Deontic.BGB.Capacity () where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Layer (Base, Proviso, SpecialRule, Resolvable)
import Deontic.Core.Adjudicate
import Deontic.BGB.Types

-- ═══════════════════════════════════════════════
-- Geschäftsfähigkeit — Capacity (BGB §104-§113)
--
-- This demonstrates jurisdiction-agnosticism:
-- the same deontic-core framework encodes German law
-- with German-specific act types, facts, and articles.
--
-- Structure mirrors Korean MinorAct but with BGB semantics:
-- §104: Geschäftsunfähig (absolutely incapable) → Void
-- §106: Beschränkt geschäftsfähig (limited capacity) → Voidable
-- §107: Lediglich rechtlicher Vorteil → Valid (proviso)
-- §110: Taschengeldparagraph → Valid (special rule)
-- ═══════════════════════════════════════════════

type instance Resolvable CapacityAct = '[SpecialRule, Proviso, Base]

-- §104 Geschäftsunfähigkeit + §106 beschränkte Geschäftsfähigkeit
-- Base layer: check capacity status
instance Adjudicate CapacityAct '[Base] where
  adjudicate (CapacityAct actor actId) facts
    -- §104: Geschäftsunfähig → Void (nichtig)
    | UnderSeven actor `Set.member` facts =
        JBase Void
          (ArticleRef "BGB" 104 (Just 1))
          "Geschäftsunfähig ist, wer nicht das siebente Lebensjahr vollendet hat."
    | PermanentlyIncapable actor `Set.member` facts =
        JBase Void
          (ArticleRef "BGB" 104 (Just 2))
          "Geschäftsunfähig ist, wer sich in einem die freie Willensbestimmung ausschließenden Zustand krankhafter Störung der Geistestätigkeit befindet."
    -- §106: beschränkt geschäftsfähig → Voidable (schwebend unwirksam)
    | IsMinor actor `Set.member` facts
    , not (hasConsent actor actId facts) =
        JBase Voidable
          (ArticleRef "BGB" 106 Nothing)
          "Ein Minderjähriger, der das siebente Lebensjahr vollendet hat, ist in der Geschäftsfähigkeit beschränkt."
    -- Full capacity
    | otherwise =
        JBase Valid
          (ArticleRef "BGB" 104 Nothing)
          "Volle Geschäftsfähigkeit — die Willenserklärung ist wirksam."

-- §107 Lediglich rechtlicher Vorteil (purely beneficial)
instance Adjudicate CapacityAct rest
      => Adjudicate CapacityAct (Proviso ': rest) where
  adjudicate act facts
    | PurelyBeneficial `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "BGB" 107 Nothing)
                  "Der Minderjährige bedarf nicht der Zustimmung des gesetzlichen Vertreters, soweit er lediglich einen rechtlichen Vorteil erlangt."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- §110 Taschengeldparagraph (pocket money)
instance Adjudicate CapacityAct rest
      => Adjudicate CapacityAct (SpecialRule ': rest) where
  adjudicate act facts
    | PocketMoney `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "BGB" 110 Nothing)
                  "Ein von dem Minderjährigen ohne Zustimmung des gesetzlichen Vertreters geschlossener Vertrag gilt als von Anfang an wirksam, wenn der Minderjährige die vertragsmäßige Leistung mit Mitteln bewirkt, die ihm zu diesem Zweck oder zu freier Verfügung überlassen worden sind."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

hasConsent :: PersonId -> ActId -> Set.Set BGBFact -> Bool
hasConsent actor actId facts =
  LegalRepConsent actor actId `Set.member` facts
