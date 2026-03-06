# Deontic Logic Curry-Howard Correspondence for Legal Code Formalization

## Goal

A practical tool for checking the validity of legal acts under Korean Civil Law (민법), grounded in a Curry-Howard correspondence for deontic logic.

## Approach: Hybrid — Typed Core with Defeasible Layer

Two layers:
- **Core layer**: a Haskell type system (GADTs, type families, typeclasses) where legal concepts are types and legal derivations are programs.
- **Defeasible layer**: a value-level priority-based rule engine for handling exceptions, conflicts between articles, and lex specialis.

Legal validity = type-checks in the core + survives defeat in the defeasible layer.

## Package Structure

Two Haskell packages in a single workspace:

### deontic-core — General deontic logic library

```
deontic-core/
  src/Deontic/
    Core/
      Types.hs        -- Base sorts: Person, Act, Thing, Right, Time
      Judgment.hs     -- Valid, Void, Voidable, Obligatory, Permitted, Forbidden
      Capacity.hs     -- Capacity framework (generic, not statute-specific)
    Defeasible/
      Rule.hs         -- Rule type, ArticleRef, priority
      Defeat.hs       -- Defeat graph construction
      Resolve.hs      -- Resolution algorithm (undefeated conclusions)
    Query.hs           -- Generic query interface
```

### deontic-kr-civil — Korean Civil Act encoding (depends on deontic-core)

```
deontic-kr-civil/
  src/Deontic/Civil/
    General.hs         -- 1장 통칙 (§1-§2)
    Persons.hs         -- 2장 인 (§3-§56)
    Things.hs          -- 3장 물건 (§98-§102)
    Acts.hs            -- 4장 법률행위 (§103-§154)
```

## Core Type System (Curry-Howard Layer)

### Base Sorts

```haskell
Person, Act, Thing, Right, Time
```

### Deontic Type Constructors

| Constructor      | Meaning                              | Curry-Howard reading                        |
|------------------|--------------------------------------|---------------------------------------------|
| `Valid a`        | Act `a` is legally valid (유효)       | A proof that `a` satisfies formation reqs   |
| `Void a`         | Act `a` is void (무효)               | A proof of a mandatory rule violation       |
| `Voidable a`     | Act `a` is voidable (취소할 수 있는)   | A defect + capability to produce `Void a`   |
| `Obligatory p a` | Person `p` must perform `a` (의무)    | A computation `p` must execute              |
| `Permitted p a`  | Person `p` may do `a` (허용)          | Evidence of no prohibition                  |
| `Forbidden p a`  | Person `p` must not do `a` (금지)     | `Act -> Void` — performing yields invalidity|

### Capacity as Types

```haskell
data Capacity (p :: PersonKind) where
  FullCapacity    :: Capacity 'Adult
  LimitedCapacity :: Guardian g -> Capacity 'Minor
  NoCapacity      :: Capacity 'Incompetent
```

### Typeclasses (Extensibility)

The core defines the algebra of deontic reasoning; statute packages supply interpretations.

```haskell
class LegalSubject a where
  capacity :: a -> Facts -> Capacity

class DeonticAct a where
  formation :: a -> Facts -> [Requirement]
  defects   :: a -> Facts -> [Defect]

class LegalCode code where
  rules    :: code -> [Rule]
  priority :: code -> ArticleRef -> ArticleRef -> Ordering

class Defeasible a where
  defeaters    :: a -> [ArticleRef]
  isDefeatedBy :: a -> a -> Facts -> Bool
```

## Defeasible Layer

Each article becomes a labeled rule:

```haskell
data Rule = Rule
  { ruleId     :: ArticleRef
  , requires   :: [Fact] -> Bool
  , concludes  :: Fact -> Judgment'
  , defeatedBy :: [ArticleRef]
  }
```

Resolution algorithm:
1. Type-check in the core layer
2. Collect all rules whose preconditions are satisfied
3. Build a defeat graph (Dung's argumentation framework)
4. Compute undefeated conclusions

## Query Interface

```haskell
checkAct    :: (DeonticAct a, LegalCode code) => code -> a -> Facts -> Result
obligations :: (LegalCode code) => code -> Person -> Facts -> [Obligation]
isPermitted :: (LegalCode code) => code -> Person -> Act -> Facts -> Bool
explain     :: (DeonticAct a, LegalCode code) => code -> a -> Facts -> ProofTree
```

Results include article provenance:

```haskell
data Result
  = IsValid    [ArticleRef]
  | IsVoid     [ArticleRef]
  | IsVoidable [ArticleRef]
  | Ambiguous  [(Judgment', [ArticleRef])]

data ProofTree
  = Leaf ArticleRef
  | Defeated ArticleRef [ArticleRef]
  | Derived  ArticleRef [ProofTree]
```

## 민법 총칙 Mapping

| Chapter | Content | System role |
|---------|---------|-------------|
| 1장 통칙 (§1-§2) | General principles | Axioms, good faith meta-constraint |
| 2장 인 (§3-§56) | Persons | Base types, capacity rules |
| 3장 물건 (§98-§102) | Things | Base types, classification |
| 4장 법률행위 (§103-§154) | Juristic acts | Core validity engine |
| 5장 기간 (§155-§161) | Periods | Time calculus |
| 6장 소멸시효 (§162-§184) | Prescription | Temporal defeaters |

### Formalization priority

1. 2장 인 (Persons) — ontology first
2. 4장 법률행위 (Juristic Acts) — core validity
3. 5장 기간 (Periods) — needed for deadlines
4. 6장 소멸시효 (Prescription) — temporal defeat
5. 1장 통칙 — good faith meta-constraint
6. 3장 물건 — classification, added as needed

## Implementation Platform

Haskell with GADTs, type families, and typeclasses. GHC plugin as future work for:
- Custom type errors referencing article numbers
- Type-level defeasibility checking
- Enhanced Korean identifier support

## GHC Plugin (Future)

Out of scope for initial build. The architecture supports it without modification.
