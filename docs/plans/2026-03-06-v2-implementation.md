# V2: Type-Level Stratified Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild deontic-core and deontic-kr-civil with type-level stratified defeasibility.

**Architecture:** Typeclass instances with context encode override layers. Judgment GADT carries full reasoning chain. GHC instance resolver replaces runtime defeat graph.

**Tech Stack:** Haskell (GHC 9.6.7), Cabal, Nix, HSpec. Heavy use of GADTs, DataKinds, TypeFamilies, UndecidableInstances.

---

### Task 1: Clean Slate — Remove V1 Source, Keep Scaffolding

**Files:**
- Delete contents of: all `.hs` files under `deontic-core/src/` and `deontic-kr-civil/src/`
- Delete contents of: all test spec files under `deontic-core/test/` and `deontic-kr-civil/test/`
- Keep: `flake.nix`, `cabal.project`, `Procfile`, `.gitignore`, `.envrc`, `flake.lock`
- Modify: both `.cabal` files (new module lists)

**Step 1: Update deontic-core.cabal**

```cabal
cabal-version: 3.0
name:          deontic-core
version:       0.2.0.0
synopsis:      Type-level stratified deontic logic framework
license:       BSD-3-Clause

library
  exposed-modules:
    Deontic.Core.Types
    Deontic.Core.Verdict
    Deontic.Core.Layer
    Deontic.Core.Adjudicate
    Deontic.Render
  hs-source-dirs: src
  build-depends:
    base       >= 4.17 && < 5,
    containers >= 0.6,
    text       >= 2.0
  default-language: GHC2021
  default-extensions:
    GADTs
    DataKinds
    TypeFamilies
    MultiParamTypeClasses
    FlexibleContexts
    FlexibleInstances
    ScopedTypeVariables
    TypeApplications
    UndecidableInstances
    StandaloneKindSignatures
    PolyKinds
    AllowAmbiguousTypes

test-suite deontic-core-test
  type:             exitcode-stdio-1.0
  main-is:          Spec.hs
  hs-source-dirs:   test
  build-depends:
    base       >= 4.17 && < 5,
    deontic-core,
    hspec      >= 2.0,
    text       >= 2.0,
    containers >= 0.6
  other-modules:
    Deontic.Core.TypesSpec
    Deontic.Core.AdjudicateSpec
  build-tool-depends:
    hspec-discover:hspec-discover
  default-language: GHC2021
  default-extensions:
    GADTs
    DataKinds
    TypeFamilies
    TypeApplications
    FlexibleContexts
    FlexibleInstances
    ScopedTypeVariables
    OverloadedStrings
```

**Step 2: Update deontic-kr-civil.cabal**

```cabal
cabal-version: 3.0
name:          deontic-kr-civil
version:       0.2.0.0
synopsis:      Korean Civil Act (민법) encoded with type-level stratified deontic logic
license:       BSD-3-Clause

library
  exposed-modules:
    Deontic.Civil.Types
    Deontic.Civil.Persons
    Deontic.Civil.Acts
    Deontic.Civil.Render
  hs-source-dirs: src
  build-depends:
    base       >= 4.17 && < 5,
    deontic-core,
    containers >= 0.6,
    text       >= 2.0
  default-language: GHC2021
  default-extensions:
    GADTs
    DataKinds
    TypeFamilies
    TypeApplications
    MultiParamTypeClasses
    FlexibleContexts
    FlexibleInstances
    ScopedTypeVariables
    UndecidableInstances
    OverloadedStrings

test-suite deontic-kr-civil-test
  type:             exitcode-stdio-1.0
  main-is:          Spec.hs
  hs-source-dirs:   test
  build-depends:
    base       >= 4.17 && < 5,
    deontic-kr-civil,
    deontic-core,
    containers >= 0.6,
    text       >= 2.0,
    hspec      >= 2.0
  other-modules:
    Deontic.Civil.PersonsSpec
    Deontic.Civil.ActsSpec
    Deontic.Civil.RenderSpec
  build-tool-depends:
    hspec-discover:hspec-discover
  default-language: GHC2021
  default-extensions:
    GADTs
    DataKinds
    TypeFamilies
    TypeApplications
    FlexibleContexts
    FlexibleInstances
    ScopedTypeVariables
    OverloadedStrings
```

**Step 3: Create stub modules, verify build**

Run: `nix develop -c cabal build all`

**Step 4: Commit**

```
git commit -m "refactor: clean slate for V2 type-level stratified design"
```

---

### Task 2: Core Types (mostly preserved from V1)

**Files:**
- Create: `deontic-core/src/Deontic/Core/Types.hs`
- Create: `deontic-core/test/Deontic/Core/TypesSpec.hs`

**Implementation:**

```haskell
module Deontic.Core.Types
  ( PersonId(..), ActId(..), ThingId(..)
  , ArticleRef(..)
  , Fact(..), Facts
  ) where

import Data.Text (Text)
import Data.Set (Set)

newtype PersonId = PersonId Text deriving (Eq, Ord, Show)
newtype ActId    = ActId Text    deriving (Eq, Ord, Show)
newtype ThingId  = ThingId Text  deriving (Eq, Ord, Show)

data ArticleRef = ArticleRef
  { articleStatute   :: Text
  , articleNumber    :: Int
  , articleParagraph :: Maybe Int
  } deriving (Eq, Ord, Show)

data Fact
  = IsNaturalPerson PersonId
  | IsJuristicPerson PersonId
  | IsMinor PersonId
  | IsAdult PersonId
  | HasGuardian PersonId PersonId
  | HasConsent PersonId ActId
  | PerformsAct PersonId ActId
  | Custom Text
  deriving (Eq, Ord, Show)

type Facts = Set Fact
```

**Test:** Same as V1. Verify ArticleRef fields and PersonId comparison.

**Commit:** `feat(core): add base types (V2)`

---

### Task 3: Verdict and Layer Types

**Files:**
- Create: `deontic-core/src/Deontic/Core/Verdict.hs`
- Create: `deontic-core/src/Deontic/Core/Layer.hs`

**Verdict.hs:**

```haskell
module Deontic.Core.Verdict
  ( Verdict(..)
  ) where

data Verdict = Valid | Void | Voidable
  deriving (Eq, Ord, Show)
```

**Layer.hs:**

```haskell
module Deontic.Core.Layer
  ( Base, Proviso, SpecialRule
  , Resolvable
  ) where

-- Type-level layer tokens
data Base           -- 원칙 (general rule)
data Proviso        -- 단서 (proviso/exception)
data SpecialRule    -- 특칙 (lex specialis)

-- Maps act type to its full layer stack
type family Resolvable act :: [*]
```

No tests needed — these are pure types with no runtime behavior.

**Commit:** `feat(core): add Verdict and type-level Layer tokens`

---

### Task 4: Adjudicate Typeclass and Judgment GADT

**Files:**
- Create: `deontic-core/src/Deontic/Core/Adjudicate.hs`
- Create: `deontic-core/test/Deontic/Core/AdjudicateSpec.hs`

**Adjudicate.hs:**

```haskell
module Deontic.Core.Adjudicate
  ( Adjudicate(..)
  , Judgment(..)
  , verdict
  , query
  ) where

import Data.Kind (Type)
import Data.Text (Text)
import GHC.TypeLits (TypeError, ErrorMessage(..))
import Deontic.Core.Types (ArticleRef, Facts)
import Deontic.Core.Verdict (Verdict)

-- | Judgment GADT — carries the full reasoning chain
data Judgment (layers :: [Type]) where
  -- | Direct rule application (base layer)
  JBase     :: Verdict -> ArticleRef -> Text
            -> Judgment '[Base]
  -- | This layer overrides the verdict from a lower layer
  JOverride :: Judgment prev -> Verdict -> ArticleRef -> Text
            -> Judgment (l ': prev)
  -- | This layer was available but delegated (did not override)
  JDelegate :: Judgment prev
            -> Judgment (l ': prev)

-- | Extract the final verdict from any judgment
verdict :: Judgment layers -> Verdict
verdict (JBase v _ _)        = v
verdict (JOverride _ v _ _)  = v
verdict (JDelegate prev)     = verdict prev

-- | Core typeclass: stratified adjudication
class Adjudicate act (layers :: [Type]) where
  adjudicate :: act -> Facts -> Judgment layers

-- | Non-resolution: empty layer stack is a type error (법의 흠결)
instance TypeError
    ( 'Text "법의 흠결 (lacuna): no applicable rule for "
      ':<>: 'ShowType act
    ) => Adjudicate act '[] where
  adjudicate = error "unreachable"

-- | Top-level query using Resolvable to determine the layer stack
query :: Adjudicate act (Resolvable act) => act -> Facts -> Judgment (Resolvable act)
query act facts = adjudicate act facts
```

Note: `query` needs `Resolvable` imported from Layer. Import it.

**Test (AdjudicateSpec.hs):** Define a minimal test act type inline to verify the machinery works:

```haskell
module Deontic.Core.AdjudicateSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Layer
import Deontic.Core.Adjudicate

-- Test act type
data TestAct = TestAct

type instance Resolvable TestAct = '[Proviso, Base]

instance Adjudicate TestAct '[Base] where
  adjudicate _ _ = JBase Voidable (ArticleRef "test" 1 Nothing) "base rule"

instance Adjudicate TestAct '[Base]
      => Adjudicate TestAct '[Proviso, Base] where
  adjudicate act facts
    | Custom "exception" `Set.member` facts =
        JOverride (adjudicate @_ @'[Base] act facts)
                  Valid
                  (ArticleRef "test" 1 (Just 2))
                  "exception applies"
    | otherwise =
        JDelegate (adjudicate @_ @'[Base] act facts)

spec :: Spec
spec = do
  describe "Adjudicate" $ do
    it "base layer returns base verdict" $ do
      let j = adjudicate @TestAct @'[Base] TestAct Set.empty
      verdict j `shouldBe` Voidable

    it "proviso layer delegates when no exception" $ do
      let j = adjudicate @TestAct @'[Proviso, Base] TestAct Set.empty
      verdict j `shouldBe` Voidable

    it "proviso layer overrides when exception present" $ do
      let j = adjudicate @TestAct @'[Proviso, Base] TestAct
                (Set.singleton (Custom "exception"))
      verdict j `shouldBe` Valid

    it "query uses Resolvable to pick layers" $ do
      let j = query TestAct Set.empty
      verdict j `shouldBe` Voidable
```

**Commit:** `feat(core): add Adjudicate typeclass, Judgment GADT, query`

---

### Task 5: Renderer — Walk Judgment GADT for Korean Output

**Files:**
- Create: `deontic-core/src/Deontic/Render.hs`

**Render.hs:**

```haskell
module Deontic.Render
  ( Renderer(..)
  , judgmentSteps
  , Step(..)
  , StepKind(..)
  ) where

import Data.Text (Text)
import Deontic.Core.Types (ArticleRef)
import Deontic.Core.Verdict (Verdict)
import Deontic.Core.Adjudicate (Judgment(..))

-- | A single step in the reasoning chain
data Step = Step
  { stepKind       :: StepKind
  , stepVerdict    :: Verdict
  , stepArticle    :: ArticleRef
  , stepSourceText :: Text
  } deriving (Eq, Show)

data StepKind = Applied | Overridden | Delegated
  deriving (Eq, Show)

-- | Extract the reasoning steps from a Judgment GADT (bottom-up)
judgmentSteps :: Judgment layers -> [Step]
judgmentSteps (JBase v ref txt) =
  [Step Applied v ref txt]
judgmentSteps (JOverride prev v ref txt) =
  judgmentSteps prev ++ [Step Overridden v ref txt]
judgmentSteps (JDelegate prev) =
  judgmentSteps prev

-- | Renderer typeclass — jurisdiction-specific output
class Renderer r where
  renderJudgment :: r -> Judgment layers -> Text
```

No test in core — tested via KoreanRenderer in deontic-kr-civil.

**Commit:** `feat(core): add Render module with Step extraction from Judgment GADT`

---

### Task 6: Civil Act Types

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/Types.hs`

**Types.hs:**

```haskell
module Deontic.Civil.Types
  ( MinorAct(..)
  , JuristicAct(..)
  ) where

import Deontic.Core.Types (PersonId, ActId)

-- | A juristic act performed by a minor (민법 제5조)
data MinorAct = MinorAct
  { maActor :: PersonId
  , maActId :: ActId
  } deriving (Eq, Show)

-- | A general juristic act (민법 제103조-제107조)
data JuristicAct = JuristicAct
  { jaActor :: PersonId
  , jaActId :: ActId
  } deriving (Eq, Show)
```

**Commit:** `feat(kr-civil): add MinorAct and JuristicAct types`

---

### Task 7: 민법 §5 — MinorAct Adjudicate Instances

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/Persons.hs`
- Create: `deontic-kr-civil/test/Deontic/Civil/PersonsSpec.hs`

**Persons.hs:**

```haskell
module Deontic.Civil.Persons () where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Layer
import Deontic.Core.Adjudicate
import Deontic.Civil.Types (MinorAct(..))

type instance Resolvable MinorAct = '[Proviso, Base]

-- 제5조(미성년자의 법률행위) ① 본문
-- "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다."
instance Adjudicate MinorAct '[Base] where
  adjudicate (MinorAct actor actId) facts
    | hasConsent actor actId facts =
        JBase Valid
          (ArticleRef "민법" 5 (Just 1))
          "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다."
    | otherwise =
        JBase Voidable
          (ArticleRef "민법" 5 (Just 1))
          "미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다."

-- 제5조 ① 단서
-- "권리만을 얻거나 의무만을 면하는 법률행위는 그러하지 아니하다."
instance Adjudicate MinorAct '[Base]
      => Adjudicate MinorAct '[Proviso, Base] where
  adjudicate act facts
    | Custom "merely-acquires-right" `Set.member` facts =
        JOverride (adjudicate @_ @'[Base] act facts)
                  Valid
                  (ArticleRef "민법" 5 (Just 1))
                  "권리만을 얻거나 의무만을 면하는 법률행위는 그러하지 아니하다."
    | otherwise =
        JDelegate (adjudicate @_ @'[Base] act facts)

hasConsent :: PersonId -> ActId -> Facts -> Bool
hasConsent _actor actId facts =
  any (\case HasConsent _ a -> a == actId; _ -> False) (Set.toList facts)
```

**Test (PersonsSpec.hs):**

```haskell
module Deontic.Civil.PersonsSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types (MinorAct(..))
import Deontic.Civil.Persons ()

spec :: Spec
spec = do
  describe "민법 제5조 — 미성년자의 법률행위" $ do
    let minor = PersonId "김철수"
        guardian = PersonId "김부모"
        act1 = ActId "매매계약"

    it "§5① 본문: 동의 없이 한 법률행위는 취소할 수 있다" $ do
      let j = query (MinorAct minor act1)
                (Set.fromList [IsMinor minor, PerformsAct minor act1])
      verdict j `shouldBe` Voidable

    it "§5① 단서: 권리만을 얻는 법률행위는 유효하다" $ do
      let j = query (MinorAct minor act1)
                (Set.fromList [ IsMinor minor
                              , PerformsAct minor act1
                              , Custom "merely-acquires-right"
                              ])
      verdict j `shouldBe` Valid

    it "§5①: 법정대리인의 동의가 있으면 유효하다" $ do
      let j = query (MinorAct minor act1)
                (Set.fromList [ IsMinor minor
                              , PerformsAct minor act1
                              , HasConsent guardian act1
                              ])
      verdict j `shouldBe` Valid
```

**Commit:** `feat(kr-civil): encode 민법 §5 with type-level stratification`

---

### Task 8: 민법 §103-§107 — JuristicAct Adjudicate Instances

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/Acts.hs`
- Create: `deontic-kr-civil/test/Deontic/Civil/ActsSpec.hs`

**Acts.hs:**

```haskell
module Deontic.Civil.Acts () where

import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Layer
import Deontic.Core.Adjudicate
import Deontic.Civil.Types (JuristicAct(..))

type instance Resolvable JuristicAct = '[SpecialRule, Proviso, Base]

-- 제107조(비진의 의사표시) — Base layer
instance Adjudicate JuristicAct '[Base] where
  adjudicate _ facts
    | Custom "hidden-intention" `Set.member` facts =
        JBase Valid
          (ArticleRef "민법" 107 (Just 1))
          "의사표시는 표의자가 진의아님을 알고 한 것이라도 그 효력에 영향을 미치지 아니한다."
    | otherwise =
        JBase Valid
          (ArticleRef "민법" 0 Nothing)
          "법률행위의 일반적 유효 추정"

-- 제107조 ② — Proviso layer
instance Adjudicate JuristicAct '[Base]
      => Adjudicate JuristicAct '[Proviso, Base] where
  adjudicate act facts
    | Custom "hidden-intention" `Set.member` facts
      && Custom "counterparty-knew" `Set.member` facts =
        JOverride (adjudicate @_ @'[Base] act facts)
                  Void
                  (ArticleRef "민법" 107 (Just 2))
                  "상대방이 표의자의 진의아님을 알았거나 알 수 있었을 경우에는 무효로 한다."
    | otherwise =
        JDelegate (adjudicate @_ @'[Base] act facts)

-- 제103조, 제104조 — SpecialRule layer (overrides everything)
instance Adjudicate JuristicAct '[Proviso, Base]
      => Adjudicate JuristicAct '[SpecialRule, Proviso, Base] where
  adjudicate act facts
    | Custom "contra-bonos-mores" `Set.member` facts =
        JOverride (adjudicate @_ @'[Proviso, Base] act facts)
                  Void
                  (ArticleRef "민법" 103 Nothing)
                  "선량한 풍속 기타 사회질서에 위반한 사항을 내용으로 하는 법률행위는 무효로 한다."
    | Custom "exploitative-act" `Set.member` facts =
        JOverride (adjudicate @_ @'[Proviso, Base] act facts)
                  Void
                  (ArticleRef "민법" 104 Nothing)
                  "당사자의 궁박, 경솔 또는 무경험으로 인하여 현저하게 공정을 잃은 법률행위는 무효로 한다."
    | otherwise =
        JDelegate (adjudicate @_ @'[Proviso, Base] act facts)
```

**Test (ActsSpec.hs):**

```haskell
module Deontic.Civil.ActsSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types (JuristicAct(..))
import Deontic.Civil.Acts ()

spec :: Spec
spec = do
  describe "민법 법률행위" $ do
    let person = PersonId "이영희"
        act1 = ActId "계약"

    it "§103: 반사회질서의 법률행위는 무효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [Custom "contra-bonos-mores"])
      verdict j `shouldBe` Void

    it "§104: 불공정한 법률행위는 무효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [Custom "exploitative-act"])
      verdict j `shouldBe` Void

    it "§107①: 비진의 의사표시는 유효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [Custom "hidden-intention"])
      verdict j `shouldBe` Valid

    it "§107②: 상대방이 안 경우 무효" $ do
      let j = query (JuristicAct person act1)
                (Set.fromList [Custom "hidden-intention", Custom "counterparty-knew"])
      verdict j `shouldBe` Void
```

**Commit:** `feat(kr-civil): encode 민법 §103-§107 with type-level stratification`

---

### Task 9: Korean Renderer

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/Render.hs`
- Create: `deontic-kr-civil/test/Deontic/Civil/RenderSpec.hs`

**Render.hs:**

```haskell
module Deontic.Civil.Render
  ( KoreanRenderer(..)
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Deontic.Core.Types (ArticleRef(..))
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate (Judgment(..))
import Deontic.Render

data KoreanRenderer = KoreanRenderer

instance Renderer KoreanRenderer where
  renderJudgment _ j =
    let steps = judgmentSteps j
        v = case steps of
              [] -> Valid
              _  -> stepVerdict (last steps)
    in T.unlines $
         [ "판단: " <> verdictText v, "", "근거:" ]
         ++ concatMap renderStep steps
         ++ ["", "따라서, " <> verdictText v]

renderStep :: Step -> [Text]
renderStep s =
  [ "  " <> articleRefText (stepArticle s) <> kindText (stepKind s)
  , "  \"" <> stepSourceText s <> "\""
  , ""
  ]

kindText :: StepKind -> Text
kindText Applied    = "에 의하면,"
kindText Overridden = "에 의하여 이를 번복하면,"
kindText Delegated  = "을 검토하였으나 해당 없어,"

verdictText :: Verdict -> Text
verdictText Valid    = "본 법률행위는 유효하다."
verdictText Void     = "본 법률행위는 무효이다."
verdictText Voidable = "본 법률행위는 취소할 수 있다."

articleRefText :: ArticleRef -> Text
articleRefText ref =
  "민법 제" <> T.pack (show (articleNumber ref)) <> "조"
  <> maybe "" (\p -> " 제" <> T.pack (show p) <> "항") (articleParagraph ref)
```

**Test:** Verify rendered output contains expected Korean strings.

**Commit:** `feat(kr-civil): add Korean legal sentence renderer for Judgment GADT`

---

## Summary

| Task | Component | What it builds |
|------|-----------|---------------|
| 1 | Clean slate | Remove V1 source, update cabal files |
| 2 | Core Types | PersonId, ActId, ArticleRef, Fact (same as V1) |
| 3 | Verdict + Layers | Verdict type, layer tokens, Resolvable family |
| 4 | Adjudicate | Typeclass, Judgment GADT, query, '[] TypeError |
| 5 | Render | Step extraction, Renderer typeclass |
| 6 | Civil Types | MinorAct, JuristicAct data types |
| 7 | 민법 §5 | Adjudicate instances for MinorAct |
| 8 | 민법 §103-§107 | Adjudicate instances for JuristicAct |
| 9 | Korean Renderer | KoreanRenderer walking Judgment GADT |
