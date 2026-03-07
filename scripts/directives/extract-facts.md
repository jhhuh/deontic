# Directive: Extract Facts and Translate to Haskell ADT

## Model

Claude (claude-opus-4-6 via Claude Code Agent tool)

## Context Provided

The subagent receives:
1. The path to `fulltext.md` in a case directory
2. This directive (including the ADT definitions below)
3. No other project knowledge

## Directive

You are a legal fact extraction agent. You have NO prior context about this project.

You will read ONE file: `fulltext.md` — a court judgment from the Korean Supreme Court.

Your task: Extract the confirmed facts from the judgment and translate each into
the Haskell ADT encoding defined below.

### Step 1: Identify the parties

Extract the key parties (persons, entities) and the legal act at issue.
Map each to a `PersonId "name"` or `ActId "name"`.

### Step 2: Extract confirmed facts

From the court's findings (인정사실, 판결요지, 이유), extract the facts that the
court confirmed as true. Only include facts the court actually found — not
allegations, arguments, or hypotheticals.

### Step 3: Translate to Haskell encoding

For each confirmed fact, find the matching `CivilFact` constructor (if one exists).
If no constructor matches, note it as `Custom "description"`.

Also determine if any domain-specific fact records apply (e.g., `PrescriptionFacts`,
`TortFacts`, etc.) and fill in their fields.

### Step 4: Write the eval expression

Construct the `CaseFacts` value and the `printResults cf` expression.

## Available ADT: CivilFact

```haskell
data CivilFact
  -- Persons
  = IsNaturalPerson PersonId
  | IsJuristicPerson PersonId
  | IsMinor PersonId
  | IsAdult PersonId
  | HasGuardian PersonId PersonId   -- (ward, guardian)
  | HasConsent PersonId ActId       -- guardian consented
  | PerformsAct PersonId ActId
  -- SS5 proviso
  | MerelyAcquiresRight
  -- SS103, SS104
  | ContraBonorsMores
  | ExploitativeAct
  -- SS107
  | HiddenIntention
  | CounterpartyKnew
  -- SS108
  | BonaFideThirdParty
  -- SS109
  | GrossNegligence
  -- SS110
  | ThirdPartyFraud
  | CounterpartyKnewFraud
  -- SS118 agency
  | SelfDealing
  -- SS125-129 apparent agency
  | IndicatedAuthority        -- SS125
  | ExceededScope             -- SS126
  | AuthorityExpired          -- SS129
  -- SS130, SS132 unauthorized agency
  | Ratified
  | CounterpartyKnewNoAuthority
  | AgentIsLimitedCapacity
  | CounterpartyCouldHaveKnown
  -- SS197, SS200 possession
  | BadFaith
  | ViolentPossession
  | ClandestinePossession
  | NoOwnershipIntent
  -- SS186-188 property transfer
  | HasRegistration
  | HasDelivery
  | IsRealProperty
  | IsMovableProperty
  | ByInheritance
  | ByCourtOrder
  | ByPublicAuction
  | ByExpropriation
```

## Available ADT: CaseFacts

```haskell
data CaseFacts = CaseFacts
  { cfActor        :: PersonId
  , cfCounterparty :: Maybe PersonId
  , cfActId        :: ActId
  , cfCivilFacts   :: Set CivilFact
  , cfDomainFacts  :: DMap DomainKey Identity
  }

defaultCaseFacts :: PersonId -> ActId -> CaseFacts
-- creates CaseFacts with empty cfCivilFacts and cfDomainFacts

domainFact :: DomainKey a -> a -> CaseFacts -> CaseFacts
-- inserts a domain-specific fact record
```

## Domain-specific fact types (use only when applicable)

```haskell
-- Prescription (SS162)
data PrescriptionFacts = PrescriptionFacts
  { pfClaimDate :: Day, pfCurrentDate :: Day
  , pfPeriodYears :: Int, pfInterruptedOn :: Maybe Day }

-- Tort (SS750)
data TortFacts = TortFacts
  { tfFault :: Bool, tfUnlawful :: Bool, tfDamage :: Bool
  , tfCausation :: Bool, tfVictimNeg :: Bool }

-- Acquisitive Prescription (SS245)
data AcqPrescFacts = AcqPrescFacts
  { apfStartDate :: Day, apfCurrentDate :: Day
  , apfGoodFaith :: Bool, apfNoNegligence :: Bool
  , apfPeaceful :: Bool, apfPublic :: Bool, apfSelfPossession :: Bool }
```

## Output format

Write a YAML file `extracted-facts.yaml` in the case directory:

```yaml
identity:
  - role: "<Korean description of party/act>"
    haskell: '<Haskell expression>'

facts:
  - description: "<Korean: what the court confirmed>"
    haskell: "<CivilFact constructor or Custom>"
    source: "<brief quote or section reference from judgment>"

eval: |
  let cf = (defaultCaseFacts (PersonId "...") (ActId "..."))
            { cfCivilFacts = Set.fromList [...] }
  in printResults cf
```

### Rules

- Only extract facts the court CONFIRMED, not argued or alleged
- Use the exact constructor names from the ADT
- If the judgment involves a legal issue not covered by any constructor, use
  `Custom "description"` and note it
- The `source` field should reference the specific part of the judgment
- Keep Korean descriptions concise (one sentence per fact)
- Do NOT read any other files. Write ONLY extracted-facts.yaml.
