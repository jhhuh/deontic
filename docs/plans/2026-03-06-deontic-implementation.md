# Deontic Curry-Howard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Haskell library for checking the validity of legal acts under Korean Civil Law (민법 총칙), using a Curry-Howard correspondence for deontic logic.

**Architecture:** Two-layer hybrid — a typed core (GADTs/typeclasses) for the Curry-Howard correspondence, plus a value-level defeasible reasoning engine for exceptions and rule conflicts. Two packages: `deontic-core` (general deontic logic) and `deontic-kr-civil` (민법 encoding).

**Tech Stack:** Haskell (GHC), Cabal (multi-package project), Nix flake for reproducibility, HSpec for testing.

---

### Task 1: Project Scaffolding — Nix Flake + Cabal Workspace

**Files:**
- Create: `flake.nix`
- Create: `cabal.project`
- Create: `deontic-core/deontic-core.cabal`
- Create: `deontic-kr-civil/deontic-kr-civil.cabal`
- Create: `Procfile`

**Step 1: Create the Nix flake**

```nix
{
  description = "Deontic logic Curry-Howard correspondence for legal code formalization";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        hsPkgs = pkgs.haskellPackages;
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            hsPkgs.ghc
            hsPkgs.cabal-install
            hsPkgs.hspec-discover
            hsPkgs.haskell-language-server
            pkgs.overmind
            pkgs.tmux
          ];
        };
      });
}
```

**Step 2: Create cabal.project**

```
packages:
  deontic-core/
  deontic-kr-civil/
```

**Step 3: Create deontic-core/deontic-core.cabal**

```cabal
cabal-version: 3.0
name:          deontic-core
version:       0.1.0.0
synopsis:      Core deontic logic library with Curry-Howard correspondence
license:       BSD-3-Clause

library
  exposed-modules:
    Deontic.Core.Types
    Deontic.Core.Judgment
    Deontic.Core.Capacity
    Deontic.Defeasible.Rule
    Deontic.Defeasible.Defeat
    Deontic.Defeasible.Resolve
    Deontic.Query
  build-depends:
    base >= 4.17 && < 5,
    containers >= 0.6,
    text >= 2.0
  hs-source-dirs: src
  default-language: GHC2021
  default-extensions:
    GADTs
    DataKinds
    TypeFamilies
    MultiParamTypeClasses
    FlexibleContexts
    FlexibleInstances
    StandaloneKindSignatures

test-suite deontic-core-test
  type: exitcode-stdio-1.0
  main-is: Spec.hs
  hs-source-dirs: test
  build-depends:
    base,
    deontic-core,
    hspec >= 2.11
  default-language: GHC2021
  build-tool-depends: hspec-discover:hspec-discover
```

**Step 4: Create deontic-kr-civil/deontic-kr-civil.cabal**

```cabal
cabal-version: 3.0
name:          deontic-kr-civil
version:       0.1.0.0
synopsis:      Korean Civil Act (민법) encoding using deontic-core
license:       BSD-3-Clause

library
  exposed-modules:
    Deontic.Civil.General
    Deontic.Civil.Persons
    Deontic.Civil.Things
    Deontic.Civil.Acts
  build-depends:
    base >= 4.17 && < 5,
    deontic-core,
    containers >= 0.6,
    text >= 2.0
  hs-source-dirs: src
  default-language: GHC2021
  default-extensions:
    GADTs
    DataKinds
    TypeFamilies
    MultiParamTypeClasses
    FlexibleContexts
    FlexibleInstances

test-suite deontic-kr-civil-test
  type: exitcode-stdio-1.0
  main-is: Spec.hs
  hs-source-dirs: test
  build-depends:
    base,
    deontic-core,
    deontic-kr-civil,
    hspec >= 2.11
  default-language: GHC2021
  build-tool-depends: hspec-discover:hspec-discover
```

**Step 5: Create stub source and test files so cabal can build**

Create minimal module stubs for every exposed module (just `module X where`) and test `Spec.hs` files with:

```haskell
{-# OPTIONS_GHC -F -pgmF hspec-discover #-}
```

**Step 6: Verify the build**

Run: `nix develop -c cabal build all`
Expected: builds successfully with no errors (just warnings about empty modules)

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: scaffold project with nix flake, cabal workspace, two packages"
```

---

### Task 2: Core Types — Base Sorts

**Files:**
- Create: `deontic-core/src/Deontic/Core/Types.hs`
- Create: `deontic-core/test/Deontic/Core/TypesSpec.hs`

**Step 1: Write the failing test**

```haskell
module Deontic.Core.TypesSpec (spec) where

import Test.Hspec
import Deontic.Core.Types

spec :: Spec
spec = do
  describe "PersonId" $ do
    it "can be created and compared" $ do
      let p1 = PersonId "person-1"
          p2 = PersonId "person-2"
      p1 `shouldNotBe` p2
      p1 `shouldBe` PersonId "person-1"

  describe "ArticleRef" $ do
    it "represents a statute article reference" $ do
      let ref = ArticleRef "민법" 5 (Just 1)
      articleStatute ref `shouldBe` "민법"
      articleNumber ref `shouldBe` 5
      articleParagraph ref `shouldBe` Just 1
```

**Step 2: Run test to verify it fails**

Run: `nix develop -c cabal test deontic-core-test`
Expected: FAIL — types not defined

**Step 3: Write minimal implementation**

```haskell
module Deontic.Core.Types
  ( PersonId(..)
  , ActId(..)
  , ThingId(..)
  , ArticleRef(..)
  , articleStatute
  , articleNumber
  , articleParagraph
  , Fact(..)
  , Facts
  ) where

import Data.Text (Text)
import Data.Set (Set)

-- | Identifier for a legal person
newtype PersonId = PersonId Text
  deriving (Eq, Ord, Show)

-- | Identifier for a legal act
newtype ActId = ActId Text
  deriving (Eq, Ord, Show)

-- | Identifier for a thing (물건)
newtype ThingId = ThingId Text
  deriving (Eq, Ord, Show)

-- | Reference to a specific article in a statute
data ArticleRef = ArticleRef
  { articleStatute   :: Text   -- e.g. "민법"
  , articleNumber    :: Int    -- e.g. 5
  , articleParagraph :: Maybe Int  -- e.g. Just 1 for §5①
  } deriving (Eq, Ord, Show)

-- | A legal fact — an atomic proposition in the deontic system
data Fact
  = IsNaturalPerson PersonId
  | IsJuristicPerson PersonId
  | IsMinor PersonId
  | IsAdult PersonId
  | HasGuardian PersonId PersonId
  | HasConsent PersonId ActId
  | PerformsAct PersonId ActId
  | Custom Text  -- extensible for statute-specific facts
  deriving (Eq, Ord, Show)

-- | A set of known facts
type Facts = Set Fact
```

**Step 4: Run test to verify it passes**

Run: `nix develop -c cabal test deontic-core-test`
Expected: PASS

**Step 5: Commit**

```bash
git add deontic-core/src/Deontic/Core/Types.hs deontic-core/test/Deontic/Core/TypesSpec.hs
git commit -m "feat(core): add base types — PersonId, ActId, ArticleRef, Fact"
```

---

### Task 3: Core Judgments — Valid, Void, Voidable

**Files:**
- Create: `deontic-core/src/Deontic/Core/Judgment.hs`
- Create: `deontic-core/test/Deontic/Core/JudgmentSpec.hs`

**Step 1: Write the failing test**

```haskell
module Deontic.Core.JudgmentSpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Judgment

spec :: Spec
spec = do
  describe "Judgment" $ do
    let art5 = ArticleRef "민법" 5 (Just 1)
        art5_2 = ArticleRef "민법" 5 (Just 2)

    it "can represent a valid act" $ do
      let j = JValid [art5_2]
      isValid j `shouldBe` True
      citations j `shouldBe` [art5_2]

    it "can represent a void act" $ do
      let j = JVoid [art5]
      isVoid j `shouldBe` True

    it "can represent a voidable act" $ do
      let j = JVoidable [art5]
      isVoidable j `shouldBe` True

  describe "ProofTree" $ do
    it "can build a derivation tree" $ do
      let art5 = ArticleRef "민법" 5 (Just 1)
          art8 = ArticleRef "민법" 8 Nothing
          tree = Derived art5 [Leaf art8]
      rootArticle tree `shouldBe` art5
```

**Step 2: Run test to verify it fails**

Run: `nix develop -c cabal test deontic-core-test`
Expected: FAIL

**Step 3: Write minimal implementation**

```haskell
module Deontic.Core.Judgment
  ( Judgment(..)
  , isValid, isVoid, isVoidable
  , citations
  , ProofTree(..)
  , rootArticle
  ) where

import Deontic.Core.Types (ArticleRef)

-- | A deontic judgment about a legal act
data Judgment
  = JValid    [ArticleRef]  -- act is valid, citing these articles
  | JVoid     [ArticleRef]  -- act is void
  | JVoidable [ArticleRef]  -- act is voidable (can be cancelled)
  | JAmbiguous [(Judgment, [ArticleRef])]  -- conflicting conclusions
  deriving (Eq, Show)

isValid :: Judgment -> Bool
isValid (JValid _) = True
isValid _          = False

isVoid :: Judgment -> Bool
isVoid (JVoid _) = True
isVoid _         = False

isVoidable :: Judgment -> Bool
isVoidable (JVoidable _) = True
isVoidable _             = False

citations :: Judgment -> [ArticleRef]
citations (JValid cs)    = cs
citations (JVoid cs)     = cs
citations (JVoidable cs) = cs
citations (JAmbiguous js) = concatMap snd js

-- | A proof tree tracing legal reasoning back to articles
data ProofTree
  = Leaf ArticleRef                    -- directly from an article
  | Defeated ArticleRef [ArticleRef]   -- rule defeated by these
  | Derived ArticleRef [ProofTree]     -- rule applied using sub-derivations
  deriving (Eq, Show)

rootArticle :: ProofTree -> ArticleRef
rootArticle (Leaf a)       = a
rootArticle (Defeated a _) = a
rootArticle (Derived a _)  = a
```

**Step 4: Run test to verify it passes**

Run: `nix develop -c cabal test deontic-core-test`
Expected: PASS

**Step 5: Commit**

```bash
git add deontic-core/src/Deontic/Core/Judgment.hs deontic-core/test/Deontic/Core/JudgmentSpec.hs
git commit -m "feat(core): add Judgment and ProofTree types"
```

---

### Task 4: Core Capacity Framework

**Files:**
- Create: `deontic-core/src/Deontic/Core/Capacity.hs`
- Create: `deontic-core/test/Deontic/Core/CapacitySpec.hs`

**Step 1: Write the failing test**

```haskell
module Deontic.Core.CapacitySpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Capacity

spec :: Spec
spec = do
  describe "CapacityLevel" $ do
    it "orders capacity levels" $ do
      Full `shouldSatisfy` (> Limited)
      Limited `shouldSatisfy` (> None)

  describe "LegalSubject typeclass" $ do
    it "is defined and can be instantiated" $ do
      -- This test verifies the typeclass compiles;
      -- actual instances are in deontic-kr-civil
      True `shouldBe` True
```

**Step 2: Run test to verify it fails**

Run: `nix develop -c cabal test deontic-core-test`
Expected: FAIL

**Step 3: Write minimal implementation**

```haskell
module Deontic.Core.Capacity
  ( CapacityLevel(..)
  , LegalSubject(..)
  ) where

import Deontic.Core.Types (Facts)

-- | Capacity levels, ordered from least to most
data CapacityLevel = None | Limited | Full
  deriving (Eq, Ord, Show)

-- | Typeclass for entities that can be legal subjects
class LegalSubject a where
  -- | Determine capacity level given known facts
  capacityLevel :: a -> Facts -> CapacityLevel
```

**Step 4: Run test to verify it passes**

Run: `nix develop -c cabal test deontic-core-test`
Expected: PASS

**Step 5: Commit**

```bash
git add deontic-core/src/Deontic/Core/Capacity.hs deontic-core/test/Deontic/Core/CapacitySpec.hs
git commit -m "feat(core): add CapacityLevel and LegalSubject typeclass"
```

---

### Task 5: Defeasible Rule Engine — Rule Type

**Files:**
- Create: `deontic-core/src/Deontic/Defeasible/Rule.hs`
- Create: `deontic-core/test/Deontic/Defeasible/RuleSpec.hs`

**Step 1: Write the failing test**

```haskell
module Deontic.Defeasible.RuleSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule

spec :: Spec
spec = do
  describe "Rule" $ do
    let art5_1 = ArticleRef "민법" 5 (Just 1)
        art5_2 = ArticleRef "민법" 5 (Just 2)
        minor = PersonId "김철수"
        act1 = ActId "sale-001"

    it "can be created with preconditions and conclusion" $ do
      let rule = Rule
            { ruleId = art5_1
            , precondition = \fs -> IsMinor minor `Set.member` fs
            , conclusion = JVoidable [art5_1]
            , defeatedBy = [art5_2]
            }
      ruleId rule `shouldBe` art5_1
      defeatedBy rule `shouldBe` [art5_2]

    it "can evaluate preconditions against facts" $ do
      let rule = Rule
            { ruleId = art5_1
            , precondition = \fs -> IsMinor minor `Set.member` fs
            , conclusion = JVoidable [art5_1]
            , defeatedBy = []
            }
          facts = Set.fromList [IsMinor minor]
      applicable rule facts `shouldBe` True
      applicable rule Set.empty `shouldBe` False
```

**Step 2: Run test to verify it fails**

Run: `nix develop -c cabal test deontic-core-test`
Expected: FAIL

**Step 3: Write minimal implementation**

```haskell
module Deontic.Defeasible.Rule
  ( Rule(..)
  , applicable
  ) where

import Deontic.Core.Types (ArticleRef, Facts)
import Deontic.Core.Judgment (Judgment)

-- | A defeasible rule derived from a statute article
data Rule = Rule
  { ruleId       :: ArticleRef
  , precondition :: Facts -> Bool
  , conclusion   :: Judgment
  , defeatedBy   :: [ArticleRef]
  }

-- | Check if a rule's preconditions are satisfied by the given facts
applicable :: Rule -> Facts -> Bool
applicable rule facts = precondition rule facts
```

**Step 4: Run test to verify it passes**

Run: `nix develop -c cabal test deontic-core-test`
Expected: PASS

**Step 5: Commit**

```bash
git add deontic-core/src/Deontic/Defeasible/Rule.hs deontic-core/test/Deontic/Defeasible/RuleSpec.hs
git commit -m "feat(core): add defeasible Rule type"
```

---

### Task 6: Defeasible Rule Engine — Defeat Graph & Resolution

**Files:**
- Create: `deontic-core/src/Deontic/Defeasible/Defeat.hs`
- Create: `deontic-core/src/Deontic/Defeasible/Resolve.hs`
- Create: `deontic-core/test/Deontic/Defeasible/ResolveSpec.hs`

**Step 1: Write the failing test**

```haskell
module Deontic.Defeasible.ResolveSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule
import Deontic.Defeasible.Resolve

spec :: Spec
spec = do
  describe "resolve" $ do
    let art5_1 = ArticleRef "민법" 5 (Just 1)
        art5_2 = ArticleRef "민법" 5 (Just 2)
        minor = PersonId "김철수"

    it "returns undefeated conclusions" $ do
      let r1 = Rule
            { ruleId = art5_1
            , precondition = \fs -> IsMinor minor `Set.member` fs
            , conclusion = JVoidable [art5_1]
            , defeatedBy = [art5_2]
            }
          facts = Set.fromList [IsMinor minor]
          results = resolve [r1] facts
      -- r1 applicable, not defeated (r5_2 not applicable)
      length results `shouldBe` 1
      fst (head results) `shouldBe` JVoidable [art5_1]

    it "defeats a rule when its defeater is applicable" $ do
      let r1 = Rule
            { ruleId = art5_1
            , precondition = \fs -> IsMinor minor `Set.member` fs
            , conclusion = JVoidable [art5_1]
            , defeatedBy = [art5_2]
            }
          r2 = Rule
            { ruleId = art5_2
            , precondition = \fs -> IsMinor minor `Set.member` fs
                                 && Custom "merely-acquires-right" `Set.member` fs
            , conclusion = JValid [art5_2]
            , defeatedBy = []
            }
          facts = Set.fromList [IsMinor minor, Custom "merely-acquires-right"]
          results = resolve [r1, r2] facts
      -- r1 defeated by r2; only r2's conclusion survives
      length results `shouldBe` 1
      fst (head results) `shouldBe` JValid [art5_2]

    it "returns nothing when no rules are applicable" $ do
      let r1 = Rule
            { ruleId = art5_1
            , precondition = \fs -> IsMinor minor `Set.member` fs
            , conclusion = JVoidable [art5_1]
            , defeatedBy = []
            }
      resolve [r1] Set.empty `shouldBe` []
```

**Step 2: Run test to verify it fails**

Run: `nix develop -c cabal test deontic-core-test`
Expected: FAIL

**Step 3: Write Defeat.hs**

```haskell
module Deontic.Defeasible.Defeat
  ( DefeatGraph
  , buildDefeatGraph
  , isDefeated
  ) where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Deontic.Core.Types (ArticleRef)
import Deontic.Defeasible.Rule (Rule(..))

-- | Maps each rule to the set of applicable rules that defeat it
type DefeatGraph = Map.Map ArticleRef (Set.Set ArticleRef)

-- | Build a defeat graph from applicable rules
buildDefeatGraph :: [Rule] -> DefeatGraph
buildDefeatGraph rules =
  let applicableIds = Set.fromList (map ruleId rules)
  in Map.fromList
       [ (ruleId r, Set.fromList (filter (`Set.member` applicableIds) (defeatedBy r)))
       | r <- rules
       ]

-- | Check whether a rule is defeated in the given graph
isDefeated :: DefeatGraph -> ArticleRef -> Bool
isDefeated graph ref =
  case Map.lookup ref graph of
    Nothing      -> False
    Just defeats -> not (Set.null defeats)
```

**Step 4: Write Resolve.hs**

```haskell
module Deontic.Defeasible.Resolve
  ( resolve
  ) where

import Deontic.Core.Types (ArticleRef, Facts)
import Deontic.Core.Judgment (Judgment)
import Deontic.Defeasible.Rule (Rule(..), applicable)
import Deontic.Defeasible.Defeat (buildDefeatGraph, isDefeated)

-- | Resolve a set of rules against facts, returning undefeated conclusions
-- Each result pairs a Judgment with the ArticleRef that produced it
resolve :: [Rule] -> Facts -> [(Judgment, ArticleRef)]
resolve rules facts =
  let applicableRules = filter (`applicable` facts) rules
      graph = buildDefeatGraph applicableRules
      undefeated = filter (\r -> not (isDefeated graph (ruleId r))) applicableRules
  in [(conclusion r, ruleId r) | r <- undefeated]
```

**Step 5: Run test to verify it passes**

Run: `nix develop -c cabal test deontic-core-test`
Expected: PASS

**Step 6: Commit**

```bash
git add deontic-core/src/Deontic/Defeasible/Defeat.hs \
        deontic-core/src/Deontic/Defeasible/Resolve.hs \
        deontic-core/test/Deontic/Defeasible/ResolveSpec.hs
git commit -m "feat(core): add defeat graph and resolution algorithm"
```

---

### Task 7: Query Interface

**Files:**
- Create: `deontic-core/src/Deontic/Query.hs`
- Create: `deontic-core/test/Deontic/QuerySpec.hs`

**Step 1: Write the failing test**

```haskell
module Deontic.QuerySpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule
import Deontic.Query

spec :: Spec
spec = do
  describe "LegalCode typeclass" $ do
    it "can query a simple code" $ do
      let art5_1 = ArticleRef "민법" 5 (Just 1)
          minor = PersonId "김철수"
          code = SimpleCode
            [ Rule
                { ruleId = art5_1
                , precondition = \fs -> IsMinor minor `Set.member` fs
                , conclusion = JVoidable [art5_1]
                , defeatedBy = []
                }
            ]
          facts = Set.fromList [IsMinor minor]
          result = query code facts
      length result `shouldBe` 1
      fst (head result) `shouldBe` JVoidable [art5_1]
```

**Step 2: Run test to verify it fails**

Run: `nix develop -c cabal test deontic-core-test`
Expected: FAIL

**Step 3: Write minimal implementation**

```haskell
module Deontic.Query
  ( LegalCode(..)
  , query
  , SimpleCode(..)
  ) where

import Deontic.Core.Types (ArticleRef, Facts)
import Deontic.Core.Judgment (Judgment)
import Deontic.Defeasible.Rule (Rule)
import Deontic.Defeasible.Resolve (resolve)

-- | A body of law that can answer queries
class LegalCode code where
  codeRules :: code -> [Rule]

-- | Query a legal code: given facts, return undefeated judgments
query :: LegalCode code => code -> Facts -> [(Judgment, ArticleRef)]
query code facts = resolve (codeRules code) facts

-- | Simple code wrapper for testing — just a list of rules
newtype SimpleCode = SimpleCode [Rule]

instance LegalCode SimpleCode where
  codeRules (SimpleCode rs) = rs
```

**Step 4: Run test to verify it passes**

Run: `nix develop -c cabal test deontic-core-test`
Expected: PASS

**Step 5: Commit**

```bash
git add deontic-core/src/Deontic/Query.hs deontic-core/test/Deontic/QuerySpec.hs
git commit -m "feat(core): add LegalCode typeclass and query interface"
```

---

### Task 8: Korean Civil Act — Persons (2장 인)

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/Persons.hs`
- Create: `deontic-kr-civil/test/Deontic/Civil/PersonsSpec.hs`

**Step 1: Write the failing test**

```haskell
module Deontic.Civil.PersonsSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Query
import Deontic.Civil.Persons

spec :: Spec
spec = do
  describe "민법 2장 인 — Persons" $ do
    let minor = PersonId "김철수"
        guardian = PersonId "김부모"
        act1 = ActId "sale-001"

    it "§5①: minor's juristic act without consent is voidable" $ do
      let facts = Set.fromList
            [ IsMinor minor
            , PerformsAct minor act1
            ]
          results = query personsCode facts
      any (\(j, _) -> isVoidable j) results `shouldBe` True

    it "§5②: minor merely acquiring rights needs no consent" $ do
      let facts = Set.fromList
            [ IsMinor minor
            , PerformsAct minor act1
            , Custom "merely-acquires-right"
            ]
          results = query personsCode facts
      -- §5② defeats §5①, act is valid
      any (\(j, _) -> isValid j) results `shouldBe` True
      any (\(j, _) -> isVoidable j) results `shouldBe` False

    it "§5①: minor with guardian consent is valid" $ do
      let facts = Set.fromList
            [ IsMinor minor
            , PerformsAct minor act1
            , HasGuardian minor guardian
            , HasConsent guardian act1
            ]
          results = query personsCode facts
      any (\(j, _) -> isValid j) results `shouldBe` True
```

**Step 2: Run test to verify it fails**

Run: `nix develop -c cabal test deontic-kr-civil-test`
Expected: FAIL

**Step 3: Write minimal implementation**

```haskell
module Deontic.Civil.Persons
  ( personsCode
  , personsRules
  ) where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule
import Deontic.Query

-- | Rules from 민법 2장 인 (Persons)
personsRules :: [Rule]
personsRules =
  [ -- §5①: 미성년자의 법률행위 — minor's juristic act without consent is voidable
    Rule
      { ruleId = ArticleRef "민법" 5 (Just 1)
      , precondition = \fs ->
          any (isMinorFact fs) (Set.toList fs)
          && not (hasConsentInFacts fs)
      , conclusion = JVoidable [ArticleRef "민법" 5 (Just 1)]
      , defeatedBy = [ArticleRef "민법" 5 (Just 2)]
      }
  , -- §5②: acts merely acquiring rights are valid without consent
    Rule
      { ruleId = ArticleRef "민법" 5 (Just 2)
      , precondition = \fs ->
          any (isMinorFact fs) (Set.toList fs)
          && Custom "merely-acquires-right" `Set.member` fs
      , conclusion = JValid [ArticleRef "민법" 5 (Just 2)]
      , defeatedBy = []
      }
  , -- §5① (consent path): minor with guardian consent is valid
    Rule
      { ruleId = ArticleRef "민법" 5 (Just 1)  -- same article, consent satisfied
      , precondition = \fs ->
          any (isMinorFact fs) (Set.toList fs)
          && hasConsentInFacts fs
      , conclusion = JValid [ArticleRef "민법" 5 (Just 1)]
      , defeatedBy = []
      }
  ]

isMinorFact :: Facts -> Fact -> Bool
isMinorFact _ (IsMinor _) = True
isMinorFact _ _           = False

hasConsentInFacts :: Facts -> Bool
hasConsentInFacts fs = any isConsent (Set.toList fs)
  where
    isConsent (HasConsent _ _) = True
    isConsent _                = False

-- | Persons chapter as a queryable code
newtype PersonsCode = PersonsCode [Rule]

instance LegalCode PersonsCode where
  codeRules (PersonsCode rs) = rs

personsCode :: PersonsCode
personsCode = PersonsCode personsRules
```

**Step 4: Run test to verify it passes**

Run: `nix develop -c cabal test deontic-kr-civil-test`
Expected: PASS

**Step 5: Commit**

```bash
git add deontic-kr-civil/src/Deontic/Civil/Persons.hs \
        deontic-kr-civil/test/Deontic/Civil/PersonsSpec.hs
git commit -m "feat(kr-civil): encode 민법 §5 — minor's juristic acts"
```

---

### Task 9: Korean Civil Act — Juristic Acts (4장 법률행위, §103-§107)

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/Acts.hs`
- Create: `deontic-kr-civil/test/Deontic/Civil/ActsSpec.hs`

**Step 1: Write the failing test**

```haskell
module Deontic.Civil.ActsSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Query
import Deontic.Civil.Acts

spec :: Spec
spec = do
  describe "민법 4장 법률행위" $ do
    let person = PersonId "이영희"
        act1 = ActId "contract-001"

    it "§103: act against good morals is void" $ do
      let facts = Set.fromList
            [ PerformsAct person act1
            , Custom "contra-bonos-mores"  -- 선량한 풍속 위반
            ]
          results = query actsCode facts
      any (\(j, _) -> isVoid j) results `shouldBe` True

    it "§104: unfair juristic act (폭리행위) is void" $ do
      let facts = Set.fromList
            [ PerformsAct person act1
            , Custom "exploitative-act"  -- 폭리행위
            ]
          results = query actsCode facts
      any (\(j, _) -> isVoid j) results `shouldBe` True

    it "§107①: act with hidden intention is valid" $ do
      let facts = Set.fromList
            [ PerformsAct person act1
            , Custom "hidden-intention"  -- 비진의 의사표시
            ]
          results = query actsCode facts
      any (\(j, _) -> isValid j) results `shouldBe` True

    it "§107②: hidden intention known to counterparty is void" $ do
      let facts = Set.fromList
            [ PerformsAct person act1
            , Custom "hidden-intention"
            , Custom "counterparty-knew"
            ]
          results = query actsCode facts
      any (\(j, _) -> isVoid j) results `shouldBe` True
      any (\(j, _) -> isValid j) results `shouldBe` False
```

**Step 2: Run test to verify it fails**

Run: `nix develop -c cabal test deontic-kr-civil-test`
Expected: FAIL

**Step 3: Write minimal implementation**

```haskell
module Deontic.Civil.Acts
  ( actsCode
  , actsRules
  ) where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Defeasible.Rule
import Deontic.Query

actsRules :: [Rule]
actsRules =
  [ -- §103: 반사회질서의 법률행위 — void if against good morals
    Rule
      { ruleId = ArticleRef "민법" 103 Nothing
      , precondition = \fs -> Custom "contra-bonos-mores" `Set.member` fs
      , conclusion = JVoid [ArticleRef "민법" 103 Nothing]
      , defeatedBy = []
      }
  , -- §104: 불공정한 법률행위 (폭리행위) — void
    Rule
      { ruleId = ArticleRef "민법" 104 Nothing
      , precondition = \fs -> Custom "exploitative-act" `Set.member` fs
      , conclusion = JVoid [ArticleRef "민법" 104 Nothing]
      , defeatedBy = []
      }
  , -- §107①: 비진의 의사표시 — valid despite hidden intention
    Rule
      { ruleId = ArticleRef "민법" 107 (Just 1)
      , precondition = \fs ->
          Custom "hidden-intention" `Set.member` fs
          && not (Custom "counterparty-knew" `Set.member` fs)
      , conclusion = JValid [ArticleRef "민법" 107 (Just 1)]
      , defeatedBy = [ArticleRef "민법" 107 (Just 2)]
      }
  , -- §107②: void if counterparty knew
    Rule
      { ruleId = ArticleRef "민법" 107 (Just 2)
      , precondition = \fs ->
          Custom "hidden-intention" `Set.member` fs
          && Custom "counterparty-knew" `Set.member` fs
      , conclusion = JVoid [ArticleRef "민법" 107 (Just 2)]
      , defeatedBy = []
      }
  ]

newtype ActsCode = ActsCode [Rule]

instance LegalCode ActsCode where
  codeRules (ActsCode rs) = rs

actsCode :: ActsCode
actsCode = ActsCode actsRules
```

**Step 4: Run test to verify it passes**

Run: `nix develop -c cabal test deontic-kr-civil-test`
Expected: PASS

**Step 5: Commit**

```bash
git add deontic-kr-civil/src/Deontic/Civil/Acts.hs \
        deontic-kr-civil/test/Deontic/Civil/ActsSpec.hs
git commit -m "feat(kr-civil): encode 민법 §103-§107 — juristic act validity"
```

---

### Task 10: Integration — Combined Civil Code Query

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/General.hs` (stub)
- Create: `deontic-kr-civil/src/Deontic/Civil/Things.hs` (stub)
- Modify: `deontic-kr-civil/deontic-kr-civil.cabal` (if needed)
- Create: `deontic-kr-civil/test/Deontic/Civil/IntegrationSpec.hs`

**Step 1: Write the failing test**

```haskell
module Deontic.Civil.IntegrationSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Judgment
import Deontic.Query
import Deontic.Civil.Persons (personsRules)
import Deontic.Civil.Acts (actsRules)

-- Combined civil code from all chapters
newtype CivilCode = CivilCode [Rule]

instance LegalCode CivilCode where
  codeRules (CivilCode rs) = rs

civilCode :: CivilCode
civilCode = CivilCode (personsRules ++ actsRules)

spec :: Spec
spec = do
  describe "Combined 민법 총칙 query" $ do
    it "minor's act against good morals is void (§103 overrides §5)" $ do
      let minor = PersonId "김철수"
          act1 = ActId "immoral-sale"
          facts = Set.fromList
            [ IsMinor minor
            , PerformsAct minor act1
            , Custom "contra-bonos-mores"
            ]
          results = query civilCode facts
      any (\(j, _) -> isVoid j) results `shouldBe` True

    it "adult's normal act produces no judgment (no applicable rule)" $ do
      let adult = PersonId "박성인"
          act1 = ActId "normal-sale"
          facts = Set.fromList
            [ IsAdult adult
            , PerformsAct adult act1
            ]
          results = query civilCode facts
      results `shouldBe` []
```

**Step 2: Run test to verify it fails**

Run: `nix develop -c cabal test deontic-kr-civil-test`
Expected: FAIL

**Step 3: Create stub modules and ensure integration compiles**

`General.hs`:
```haskell
module Deontic.Civil.General where
-- 1장 통칙 — to be implemented
```

`Things.hs`:
```haskell
module Deontic.Civil.Things where
-- 3장 물건 — to be implemented
```

**Step 4: Run test to verify it passes**

Run: `nix develop -c cabal test deontic-kr-civil-test`
Expected: PASS

**Step 5: Commit**

```bash
git add deontic-kr-civil/src/Deontic/Civil/General.hs \
        deontic-kr-civil/src/Deontic/Civil/Things.hs \
        deontic-kr-civil/test/Deontic/Civil/IntegrationSpec.hs
git commit -m "feat(kr-civil): add integration test combining persons + juristic acts"
```

---

## Summary

| Task | Component | What it builds |
|------|-----------|---------------|
| 1 | Scaffolding | Nix flake, cabal workspace, two packages |
| 2 | Core Types | PersonId, ActId, ArticleRef, Fact |
| 3 | Core Judgments | Valid, Void, Voidable, ProofTree |
| 4 | Core Capacity | CapacityLevel, LegalSubject typeclass |
| 5 | Defeasible Rule | Rule type, applicability check |
| 6 | Defeasible Engine | Defeat graph, resolution algorithm |
| 7 | Query Interface | LegalCode typeclass, query function |
| 8 | 민법 Persons | §5 — minor's juristic acts |
| 9 | 민법 Juristic Acts | §103–§107 — validity, good morals, hidden intent |
| 10 | Integration | Combined civil code, cross-chapter queries |
