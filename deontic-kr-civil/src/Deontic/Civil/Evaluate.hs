{-# LANGUAGE LambdaCase #-}
-- | Omnibus evaluator: runs all act types against a unified set of facts.
--
-- Given a 'CaseFacts', 'evaluateAll' constructs every applicable act type,
-- queries the framework, and returns non-trivial results. The only human
-- input is the fact mapping; everything else is mechanical.
module Deontic.Civil.Evaluate
  ( CaseFacts(..)
  , CaseResult(..)
  , evaluateAll
  , defaultCaseFacts
  , domainFact
  ) where

import Data.Functor.Identity (Identity(..))
import Data.Maybe (catMaybes)
import Data.Text (Text)
import qualified Data.Set as Set
import qualified Data.Dependent.Map as DMap

import Deontic.Core.Types (PersonId, ActId, ArticleRef(..))
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render (judgmentSteps, Step(..), StepKind(..))
import Deontic.Civil.Types

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

-- | Unified case facts. The omnibus input to 'evaluateAll'.
--
-- Boolean/flag facts go in 'cfCivilFacts'. Structured facts for
-- domain-specific act types are stored in a 'DMap.DMap' keyed by
-- 'DomainKey' — only provided when the case involves that legal issue.
data CaseFacts = CaseFacts
  { cfActor        :: PersonId          -- ^ 행위자/표의자
  , cfCounterparty :: Maybe PersonId    -- ^ 상대방 (agency, tort)
  , cfActId        :: ActId             -- ^ 행위 식별자
  , cfCivilFacts   :: Set.Set CivilFact -- ^ Boolean/flag facts
  , cfDomainFacts  :: DMap.DMap DomainKey Identity
  }

-- | Convenience constructor with all optional fields empty.
defaultCaseFacts :: PersonId -> ActId -> CaseFacts
defaultCaseFacts actor actId = CaseFacts
  { cfActor        = actor
  , cfCounterparty = Nothing
  , cfActId        = actId
  , cfCivilFacts   = Set.empty
  , cfDomainFacts  = DMap.empty
  }

-- | Insert a domain-specific fact record into a 'CaseFacts'.
domainFact :: DomainKey a -> a -> CaseFacts -> CaseFacts
domainFact k v cf = cf { cfDomainFacts = DMap.insert k (Identity v) (cfDomainFacts cf) }

-- | Look up a domain fact.
lookupDomain :: DomainKey a -> CaseFacts -> Maybe a
lookupDomain k cf = runIdentity <$> DMap.lookup k (cfDomainFacts cf)

-- | A single evaluation result.
data CaseResult = CaseResult
  { crLabel    :: Text           -- ^ Human-readable label (e.g., "미성년자 (§5)")
  , crJudgment :: SomeJudgment   -- ^ The full judgment
  }

-- | Run all act types against the case facts.
-- Returns only non-trivial results (see 'isTriviallyValid').
--
-- Act types with unconditional base verdicts (ShamAct → always Void,
-- MistakeAct → always Voidable, etc.) require a trigger fact to be
-- present, because selecting that act type IS the relevant fact in the
-- real legal analysis.
evaluateAll :: CaseFacts -> [CaseResult]
evaluateAll cf = filter (not . isTriviallyValid) $ catMaybes
  -- ── Set CivilFact act types ──
  -- MinorAct: relevant if IsMinor is present
  [ guarded (anyMinor (cfCivilFacts cf)) $ cr "미성년자 (§5)"
      (query (MinorAct (cfActor cf) (cfActId cf)) (cfCivilFacts cf))
  -- JuristicAct: relevant if any §103-107 trigger present
  , guarded (hasAny [ContraBonorsMores, ExploitativeAct, HiddenIntention] (cfCivilFacts cf))
      $ cr "법률행위 (§103-107)"
      (query (JuristicAct (cfActor cf) (cfActId cf)) (cfCivilFacts cf))
  -- ShamAct: always Void, only relevant if explicitly indicated
  , guarded (BonaFideThirdParty `Set.member` cfCivilFacts cf)
      $ cr "통정허위표시 (§108)"
      (query (ShamAct (cfActor cf) (cfActId cf)) (cfCivilFacts cf))
  -- MistakeAct: relevant if GrossNegligence is present (mistake is the issue)
  , guarded (GrossNegligence `Set.member` cfCivilFacts cf)
      $ cr "착오 (§109)"
      (query (MistakeAct (cfActor cf) (cfActId cf)) (cfCivilFacts cf))
  -- FraudAct: relevant if any §110 trigger present
  , guarded (hasAny [ThirdPartyFraud, CounterpartyKnewFraud] (cfCivilFacts cf))
      $ cr "사기·강박 (§110)"
      (query (FraudAct (cfActor cf) (cfActId cf)) (cfCivilFacts cf))
  -- AuthAgencyAct: relevant if SelfDealing present
  , guarded (SelfDealing `Set.member` cfCivilFacts cf)
      $ cr "유권대리 (§114, §118)"
      (query (AuthAgencyAct (cfActor cf) (agent cf) (cfActId cf)) (cfCivilFacts cf))
  -- UnauthAgencyAct: relevant if any agency trigger present
  , guarded (hasAny [Ratified, IndicatedAuthority, ExceededScope, AuthorityExpired] (cfCivilFacts cf))
      $ cr "무권대리 (§125-132)"
      (query (UnauthAgencyAct (cfActor cf) (agent cf) (cfActId cf)) (cfCivilFacts cf))
  -- PossessionAct: relevant if any rebuttal fact present
  , guarded (hasAny [BadFaith, ViolentPossession, ClandestinePossession, NoOwnershipIntent] (cfCivilFacts cf))
      $ cr "점유 추정 (§197, §200)"
      (query (PossessionAct (cfActor cf) (cfActId cf)) (cfCivilFacts cf))
  -- PropertyTransferAct: relevant if any property transfer fact present
  , guarded (hasAny [HasRegistration, HasDelivery, IsRealProperty, IsMovableProperty,
                     ByInheritance, ByCourtOrder, ByPublicAuction, ByExpropriation] (cfCivilFacts cf))
      $ cr "물권변동 (§186-188)"
      (query (PropertyTransferAct (cfActor cf) (cfActId cf)) (cfCivilFacts cf))
  -- AgencyWithdrawalAct: relevant if CounterpartyKnewNoAuthority present
  , guarded (CounterpartyKnewNoAuthority `Set.member` cfCivilFacts cf)
      $ cr "상대방의 철회권 (§134)"
      (query (AgencyWithdrawalAct (cfActor cf) (agent cf) (cfActId cf)) (cfCivilFacts cf))
  -- AgentLiabilityAct: relevant if agent capacity facts present
  , guarded (hasAny [AgentIsLimitedCapacity, CounterpartyCouldHaveKnown] (cfCivilFacts cf))
      $ cr "무권대리인의 책임 (§135)"
      (query (AgentLiabilityAct (agent cf) (cfActor cf) (cfActId cf)) (cfCivilFacts cf))
  -- ── Domain-record act types (run only when facts provided) ──
  , fmap (\pf -> cr "소멸시효 (§162)"
      (query (PrescriptionAct (cfActor cf) (cfActId cf)) pf))
      (lookupDomain PrescriptionK cf)
  , fmap (\tf -> cr "불법행위 (§750, §396)"
      (query (TortAct (cfActor cf) (agent cf) (cfActId cf)) tf))
      (lookupDomain TortK cf)
  , fmap (\cof -> cr "공유물의 처분 (§264)"
      (query (CoOwnershipAct (cfActId cf)) cof))
      (lookupDomain CoOwnershipK cf)
  , fmap (\rf -> cr "취소의 제척기간 (§146)"
      (query (RescissionAct (cfActor cf) (cfActId cf)) rf))
      (lookupDomain RescissionK cf)
  , fmap (\apf -> cr "취득시효 (§245)"
      (query (AcqPrescriptionAct (cfActor cf) (cfActId cf)) apf))
      (lookupDomain AcqPrescK cf)
  , fmap (\df -> cr "채무불이행 (§387-390)"
      (query (DefaultAct (cfActor cf) (agent cf) (cfActId cf)) df))
      (lookupDomain DefaultK cf)
  , fmap (\wf -> cr "하자담보 (§580-582)"
      (query (WarrantyAct (cfActor cf) (cfActId cf)) wf))
      (lookupDomain WarrantyK cf)
  , fmap (\lf -> cr "임대차 (§618-640)"
      (query (LeaseAct (cfActor cf) (agent cf) (cfActId cf)) lf))
      (lookupDomain LeaseK cf)
  , fmap (\pif -> cr "일부무효/전환/추인 (§137-139)"
      (query (PartialInvalidityAct (cfActId cf)) pif))
      (lookupDomain InvalidityK cf)
  , fmap (\cnf -> cr "조건부 법률행위 (§147-152)"
      (query (ConditionalAct (cfActId cf)) cnf))
      (lookupDomain ConditionalK cf)
  ]
  where
    agent cf' = maybe (cfActor cf') id (cfCounterparty cf')
    cr label j = CaseResult label (SomeJudgment j)

-- | A judgment is trivially Valid if:
-- 1. The final verdict is Valid, AND
-- 2. No override occurred (only Applied/Delegated steps)
--
-- This filters out act types that are simply not relevant to the case.
-- A Valid verdict reached via override (e.g., §5 단서) is non-trivial.
isTriviallyValid :: CaseResult -> Bool
isTriviallyValid (CaseResult _ (SomeJudgment j)) =
  verdict j == Valid && all (\s -> stepKind s /= Overridden) (judgmentSteps j)

-- | Guard: include result only if condition is True.
guarded :: Bool -> CaseResult -> Maybe CaseResult
guarded True  r = Just r
guarded False _ = Nothing

-- | Check if any of the given facts are present in the set.
hasAny :: [CivilFact] -> Set.Set CivilFact -> Bool
hasAny fs s = any (`Set.member` s) fs

-- | Check if any IsMinor fact is present.
anyMinor :: Set.Set CivilFact -> Bool
anyMinor = any (\case IsMinor _ -> True; _ -> False) . Set.toList
