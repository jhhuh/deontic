# 총칙 Remainder (§134–§161) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Encode Korean Civil Act §134–§152 (agency remedies, invalidity meta-rules, cancellation/ratification, conditional acts) to complete 총칙 coverage.

**Architecture:** Four new instance modules + expanded Types.hs. Each module is an independent Adjudicate instance set with its own act type, fact record, and layer stack. CancellableAct introduces a wrapper pattern that takes a prior Verdict as input.

**Tech Stack:** Haskell (GHC 9.6, GHC2021), deontic-core framework, hspec for tests. Build with `nix develop -c cabal build deontic-kr-civil`. Test with `nix develop -c cabal test deontic-kr-civil`.

---

### Task 1: Add new types to Types.hs

**Files:**
- Modify: `deontic-kr-civil/src/Deontic/Civil/Types.hs`

**Context:** All act types, fact records, layer tokens, and Facts type instances live in Types.hs. Follow the existing pattern: act type with PersonId/ActId fields, fact record with domain-specific fields, uninhabited data types for layer tokens, and open type family instances.

**Step 1: Add the new types after the existing LeaseAct/LeaseFacts block (after line 329)**

Add these types before the `CivilFact` data declaration:

```haskell
-- | 상대방의 철회권 (민법 제134조)
data AgencyWithdrawalAct = AgencyWithdrawalAct
  { awPrincipal    :: PersonId  -- 본인
  , awCounterparty :: PersonId  -- 상대방
  , awActId        :: ActId
  } deriving (Eq, Show)

-- | 무권대리인의 책임 (민법 제135조)
data AgentLiabilityAct = AgentLiabilityAct
  { alAgent        :: PersonId  -- 무권대리인
  , alCounterparty :: PersonId  -- 상대방
  , alActId        :: ActId
  } deriving (Eq, Show)

-- | 법률행위의 일부무효/전환/추인 (민법 제137조-제139조)
data PartialInvalidityAct = PartialInvalidityAct
  { piActId :: ActId
  } deriving (Eq, Show)

-- | 일부무효 판단에 필요한 사실관계
data PartialInvalidityFacts = PartialInvalidityFacts
  { pifPartVoid              :: Bool  -- 일부분이 무효
  , pifHypotheticalIntent    :: Bool  -- 무효부분 없이도 행위했을 것 (§137 단서)
  , pifMeetsOtherReqs        :: Bool  -- 다른 법률행위 요건 구비 (§138)
  , pifConversionIntent      :: Bool  -- 다른 행위를 의욕 (§138)
  , pifRatifiedWithKnowledge :: Bool  -- 무효 알고 추인 (§139)
  } deriving (Eq, Show)

-- | 취소할 수 있는 행위의 취소/추인 (민법 제141조, 제143조-제145조)
-- 다른 act type의 query 결과(Verdict)를 입력으로 받는 wrapper pattern.
data CancellableAct = CancellableAct
  { caActId       :: ActId
  , caPriorVerdict :: Verdict
  } deriving (Eq, Show)

-- | 취소/추인 판단에 필요한 사실관계
data CancellationFacts = CancellationFacts
  { cnfCancelled          :: Bool                                -- 취소권 행사 (§141)
  , cnfRatified           :: Bool                                -- 추인 (§143)
  , cnfCauseCeased        :: Bool                                -- 취소원인 소멸 (§144①)
  , cnfRatifierIsGuardian :: Bool                                -- 법정대리인/후견인 (§144②)
  , cnfConstructive       :: Maybe ConstructiveRatificationEvent -- 법정추인 사유 (§145)
  , cnfObjectionReserved  :: Bool                                -- 이의 보류 (§145 단서)
  } deriving (Eq, Show)

-- | 법정추인 사유 (민법 제145조)
data ConstructiveRatificationEvent
  = FullOrPartialPerformance  -- 전부 또는 일부의 이행
  | DemandForPerformance      -- 이행의 청구
  | Novation                  -- 경개
  | SecurityProvision         -- 담보의 제공
  | RightAssignment           -- 취소할 수 있는 행위로 취득한 권리의 전부 또는 일부의 양도
  | CompulsoryExecution        -- 강제집행
  deriving (Eq, Ord, Show)

-- | 조건부/기한부 법률행위 (민법 제147조, 제150조-제152조)
data ConditionalAct = ConditionalAct
  { condActId :: ActId
  } deriving (Eq, Show)

-- | 조건의 유형
data ConditionType
  = Suspensive  -- 정지조건 (§147①)
  | Resolutive  -- 해제조건 (§147②)
  | StartDate   -- 시기 (§152①)
  | EndDate     -- 종기 (§152②)
  deriving (Eq, Ord, Show)

-- | 조건의 상태
data ConditionState
  = CondPending     -- 미성취
  | CondFulfilled   -- 성취
  | CondImpossible  -- 성취 불가능
  | CondIllegal     -- 불법조건
  deriving (Eq, Ord, Show)

-- | 반신의행위의 유형 (민법 제150조)
data BadFaithKind
  = BadFaithPrevention  -- 조건 성취 방해 (§150①)
  | BadFaithCausation   -- 조건 성취 야기 (§150②)
  deriving (Eq, Ord, Show)

-- | 조건부 법률행위 판단에 필요한 사실관계
data ConditionalFacts = ConditionalFacts
  { condType     :: ConditionType
  , condState    :: ConditionState
  , condBadFaith :: Maybe BadFaithKind
  } deriving (Eq, Show)
```

**Step 2: Add layer tokens after existing RenewalRight token (after line 244)**

```haskell
-- Layer tokens for agency remedies (무권대리 구제)
data CounterpartyKnowledge  -- §134 상대방의 악의

-- Layer tokens for partial invalidity (일부무효)
data HypotheticalIntent     -- §137 단서 가정적 의사
data Conversion             -- §138 무효행위의 전환

-- Layer tokens for cancellation (취소/추인)
data GeneralRatification       -- §143 추인
data ConstructiveRatification  -- §145 법정추인

-- Layer tokens for conditional acts (조건부 법률행위)
data IllegalCondition    -- §151 불법조건/기성조건
data BadFaithCondition   -- §150 반신의행위
```

**Step 3: Add CivilFact constructors for agency remedies (in the CivilFact data declaration)**

After the existing `| Ratified` constructor, add:

```haskell
  | CounterpartyKnewNoAuthority  -- §134 상대방이 대리권 없음을 안 때
  | AgentIsLimitedCapacity       -- §135② 대리인이 제한능력자
  | CounterpartyCouldHaveKnown   -- §135② 상대방이 알 수 있었을 때
```

**Step 4: Add Facts type instances at the end of the file**

```haskell
type instance Facts AgencyWithdrawalAct   = Set CivilFact
type instance Facts AgentLiabilityAct     = Set CivilFact
type instance Facts PartialInvalidityAct  = PartialInvalidityFacts
type instance Facts CancellableAct        = CancellationFacts
type instance Facts ConditionalAct        = ConditionalFacts
```

**Step 5: Add new exports to module header**

Add to the export list:
```haskell
  , AgencyWithdrawalAct(..)
  , AgentLiabilityAct(..)
  , PartialInvalidityAct(..)
  , PartialInvalidityFacts(..)
  , CancellableAct(..)
  , CancellationFacts(..)
  , ConstructiveRatificationEvent(..)
  , ConditionalAct(..)
  , ConditionType(..)
  , ConditionState(..)
  , BadFaithKind(..)
  , ConditionalFacts(..)
  , CounterpartyKnowledge
  , HypotheticalIntent, Conversion
  , GeneralRatification, ConstructiveRatification
  , IllegalCondition, BadFaithCondition
```

**Step 6: Import Verdict in Types.hs**

Add to imports:
```haskell
import Deontic.Core.Verdict (Verdict)
```

This is needed because `CancellableAct` has a `Verdict` field.

**Step 7: Build to verify types compile**

Run: `nix develop -c cabal build deontic-kr-civil`
Expected: compiles with no errors

**Step 8: Commit**

```bash
git add deontic-kr-civil/src/Deontic/Civil/Types.hs
git commit -m "feat: add types for §134-§152 (agency remedies, invalidity, cancellation, conditions)"
```

---

### Task 2: AgencyRemedies module (§134–§135)

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/AgencyRemedies.hs`
- Create: `deontic-kr-civil/test/Deontic/Civil/AgencyRemediesSpec.hs`
- Modify: `deontic-kr-civil/deontic-kr-civil.cabal` (add to exposed-modules and other-modules)

**Context:** §134 — counterparty can withdraw from unauthorized agency contract unless they knew of lack of authority. §135 — unauthorized agent is liable unless counterparty knew/could have known or agent is limited-capacity. These use `Set CivilFact` as their Facts type, following the pattern from `Agency.hs`.

**Step 1: Write the test file**

```haskell
module Deontic.Civil.AgencyRemediesSpec (spec) where

import Test.Hspec
import Data.Set qualified as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Civil.Types
import Deontic.Civil.AgencyRemedies ()

spec :: Spec
spec = do
  describe "상대방의 철회권 (§134)" $ do
    let principal    = PersonId "갑"
        counterparty = PersonId "을"
        actId        = ActId "매매계약"
        act          = AgencyWithdrawalAct principal counterparty actId

    it "§134 본문: 추인 전 상대방은 철회 가능 → Valid" $ do
      let j = query act Set.empty
      verdict j `shouldBe` Valid

    it "§134 단서: 상대방이 무권대리를 안 때 → Void (철회불가)" $ do
      let j = query act (Set.singleton CounterpartyKnewNoAuthority)
      verdict j `shouldBe` Void

  describe "무권대리인의 책임 (§135)" $ do
    let agent        = PersonId "병"
        counterparty = PersonId "을"
        actId        = ActId "매매계약"
        act          = AgentLiabilityAct agent counterparty actId

    it "§135①: 무권대리인은 이행 또는 손해배상 책임 → Void" $ do
      let j = query act Set.empty
      verdict j `shouldBe` Void

    it "§135②: 상대방이 무권대리를 안 때 → Valid (면책)" $ do
      let j = query act (Set.singleton CounterpartyKnewNoAuthority)
      verdict j `shouldBe` Valid

    it "§135②: 상대방이 알 수 있었을 때 → Valid (면책)" $ do
      let j = query act (Set.singleton CounterpartyCouldHaveKnown)
      verdict j `shouldBe` Valid

    it "§135②: 대리인이 제한능력자 → Valid (면책)" $ do
      let j = query act (Set.singleton AgentIsLimitedCapacity)
      verdict j `shouldBe` Valid
```

**Step 2: Write the implementation**

```haskell
module Deontic.Civil.AgencyRemedies () where

import Data.Set qualified as Set
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Proviso, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 무권대리의 구제 — Agency Remedies (§134-§135)
--
-- §134: 상대방의 철회권 (counterparty withdrawal)
--   본문: 추인이 있을 때까지 상대방은 철회 가능.
--   단서: 상대방이 대리권 없음을 안 때에는 철회 불가.
--
-- §135: 무권대리인의 책임 (agent liability)
--   ①: 이행 또는 손해배상 책임.
--   ②: 상대방 악의/과실 또는 대리인 제한능력자이면 면책.
-- ═══════════════════════════════════════════════

-- § 134: 상대방의 철회권
type instance Resolvable AgencyWithdrawalAct = '[CounterpartyKnowledge, Base]

instance Adjudicate AgencyWithdrawalAct '[Base] where
  adjudicate _ _ =
    JBase Valid
      (ArticleRef "민법" 134 Nothing)
      "본인의 추인이 있을 때까지 상대방은 본인이나 그 대리인에 대하여 철회할 수 있다."

instance Adjudicate AgencyWithdrawalAct rest
      => Adjudicate AgencyWithdrawalAct (CounterpartyKnowledge ': rest) where
  adjudicate act facts
    | Set.member CounterpartyKnewNoAuthority facts =
        JOverride (adjudicate @_ @rest act facts)
                  Void
                  (ArticleRef "민법" 134 Nothing)
                  "계약 당시에 상대방이 대리권 없음을 안 때에는 철회하지 못한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- § 135: 무권대리인의 책임
type instance Resolvable AgentLiabilityAct = '[Proviso, Base]

instance Adjudicate AgentLiabilityAct '[Base] where
  adjudicate _ _ =
    JBase Void
      (ArticleRef "민법" 135 (Just 1))
      "대리권을 증명하지 못하고 본인의 추인을 받지 못한 자는 상대방의 선택에 따라 이행 또는 손해배상의 책임이 있다."

instance Adjudicate AgentLiabilityAct rest
      => Adjudicate AgentLiabilityAct (Proviso ': rest) where
  adjudicate act facts
    | Set.member CounterpartyKnewNoAuthority facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 135 (Just 2))
                  "상대방이 대리권 없음을 안 때에는 무권대리인의 책임이 없다."
    | Set.member CounterpartyCouldHaveKnown facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 135 (Just 2))
                  "상대방이 대리권 없음을 알 수 있었을 때에는 무권대리인의 책임이 없다."
    | Set.member AgentIsLimitedCapacity facts =
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 135 (Just 2))
                  "대리인이 제한능력자인 때에는 무권대리인의 책임이 없다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
```

**Step 3: Add to cabal file**

In `deontic-kr-civil.cabal`, add `Deontic.Civil.AgencyRemedies` to `exposed-modules` and `Deontic.Civil.AgencyRemediesSpec` to `other-modules` in the test-suite.

**Step 4: Run tests**

Run: `nix develop -c cabal test deontic-kr-civil`
Expected: all tests pass including the 6 new agency remedies tests

**Step 5: Commit**

```bash
git add deontic-kr-civil/src/Deontic/Civil/AgencyRemedies.hs \
        deontic-kr-civil/test/Deontic/Civil/AgencyRemediesSpec.hs \
        deontic-kr-civil/deontic-kr-civil.cabal
git commit -m "feat: add §134-§135 agency remedies (withdrawal right, agent liability)"
```

---

### Task 3: Invalidity module (§137–§139)

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/Invalidity.hs`
- Create: `deontic-kr-civil/test/Deontic/Civil/InvaliditySpec.hs`
- Modify: `deontic-kr-civil/deontic-kr-civil.cabal`

**Context:** §137 — partial invalidity makes whole act void, unless parties would have acted without the void part. §138 — void act can be converted to a different valid act. §139 — ratification of void act is ineffective, but ratification with knowledge = new act. Uses `PartialInvalidityFacts` record. Three layers: `Conversion > HypotheticalIntent > Base`.

**Step 1: Write the test file**

```haskell
module Deontic.Civil.InvaliditySpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Invalidity ()

spec :: Spec
spec = do
  describe "법률행위의 일부무효/전환/추인 (§137-§139)" $ do
    let actId = ActId "매매계약"
        act   = PartialInvalidityAct actId
        baseFacts = PartialInvalidityFacts
          { pifPartVoid              = True
          , pifHypotheticalIntent    = False
          , pifMeetsOtherReqs        = False
          , pifConversionIntent      = False
          , pifRatifiedWithKnowledge = False
          }

    it "§137 본문: 일부 무효 → Void (전부 무효)" $ do
      let j = query act baseFacts
      verdict j `shouldBe` Void

    it "§137: 일부 무효 아님 → Valid" $ do
      let j = query act baseFacts { pifPartVoid = False }
      verdict j `shouldBe` Valid

    it "§137 단서: 가정적 의사 인정 → Valid (나머지 유효)" $ do
      let j = query act baseFacts { pifHypotheticalIntent = True }
      verdict j `shouldBe` Valid

    it "§138: 다른 행위 요건 구비 + 의욕 → Valid (전환)" $ do
      let j = query act baseFacts
                { pifMeetsOtherReqs = True
                , pifConversionIntent = True
                }
      verdict j `shouldBe` Valid

    it "§138: 요건 구비하나 의욕 없음 → Void (전환 안됨)" $ do
      let j = query act baseFacts
                { pifMeetsOtherReqs = True
                , pifConversionIntent = False
                }
      verdict j `shouldBe` Void

    it "§139: 무효 알고 추인 → Valid (새로운 법률행위)" $ do
      let j = query act baseFacts { pifRatifiedWithKnowledge = True }
      verdict j `shouldBe` Valid

    it "§139: 무효 모르고 추인 → Void (추인 무효)" $ do
      let j = query act baseFacts { pifRatifiedWithKnowledge = False }
      verdict j `shouldBe` Void

    it "§138: 전환의 근거조문은 §138" $ do
      let j = query act baseFacts
                { pifMeetsOtherReqs = True
                , pifConversionIntent = True
                }
          steps = judgmentSteps j
      articleNumber (stepArticle (last steps)) `shouldBe` 138
```

**Step 2: Write the implementation**

```haskell
module Deontic.Civil.Invalidity () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 법률행위의 무효 — Invalidity of Juristic Acts (§137-§139)
--
-- §137: 일부무효 → 전부무효. 단서: 가정적 의사 → 나머지 유효.
-- §138: 무효행위의 전환. 다른 행위 요건 + 의욕 → 유효.
-- §139: 무효행위의 추인. 추인 무효. 단서: 알고 추인 → 새 행위.
-- ═══════════════════════════════════════════════

type instance Resolvable PartialInvalidityAct = '[Conversion, HypotheticalIntent, Base]

-- §137 본문: 일부 무효이면 전부 무효
instance Adjudicate PartialInvalidityAct '[Base] where
  adjudicate _ facts
    | pifPartVoid facts =
        JBase Void
          (ArticleRef "민법" 137 Nothing)
          "법률행위의 일부분이 무효인 때에는 그 전부를 무효로 한다."
    | otherwise =
        JBase Valid
          (ArticleRef "민법" 137 Nothing)
          "법률행위의 일부분이 무효가 아니므로 전부 유효하다."

-- §137 단서 + §139 단서
instance Adjudicate PartialInvalidityAct rest
      => Adjudicate PartialInvalidityAct (HypotheticalIntent ': rest) where
  adjudicate act facts
    | pifHypotheticalIntent facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 137 Nothing)
                  "그 무효부분이 없더라도 법률행위를 하였을 것이라고 인정되므로 나머지 부분은 유효하다."
    | pifRatifiedWithKnowledge facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 139 Nothing)
                  "당사자가 그 무효임을 알고 추인한 때에는 새로운 법률행위로 본다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- §138 무효행위의 전환
instance Adjudicate PartialInvalidityAct rest
      => Adjudicate PartialInvalidityAct (Conversion ': rest) where
  adjudicate act facts
    | pifMeetsOtherReqs facts
    , pifConversionIntent facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 138 Nothing)
                  "무효인 법률행위가 다른 법률행위의 요건을 구비하고 당사자가 그 무효를 알았더라면 다른 법률행위를 하는 것을 의욕하였으리라고 인정되므로 다른 법률행위로서 효력을 가진다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
```

**Step 3: Add to cabal file**

Add `Deontic.Civil.Invalidity` to `exposed-modules` and `Deontic.Civil.InvaliditySpec` to `other-modules`.

**Step 4: Run tests**

Run: `nix develop -c cabal test deontic-kr-civil`
Expected: all tests pass including the 8 new invalidity tests

**Step 5: Commit**

```bash
git add deontic-kr-civil/src/Deontic/Civil/Invalidity.hs \
        deontic-kr-civil/test/Deontic/Civil/InvaliditySpec.hs \
        deontic-kr-civil/deontic-kr-civil.cabal
git commit -m "feat: add §137-§139 invalidity rules (partial invalidity, conversion, void ratification)"
```

---

### Task 4: Cancellation module (§141, §143–§145)

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/Cancellation.hs`
- Create: `deontic-kr-civil/test/Deontic/Civil/CancellationSpec.hs`
- Modify: `deontic-kr-civil/deontic-kr-civil.cabal`

**Context:** CancellableAct is a wrapper — its `caPriorVerdict` field comes from a previous `query` call. The module only acts on Voidable inputs; non-Voidable passes through. Three layers: `ConstructiveRatification > GeneralRatification > Base`.

**Step 1: Write the test file**

```haskell
module Deontic.Civil.CancellationSpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.Cancellation ()

spec :: Spec
spec = do
  describe "취소/추인 (§141, §143-§145)" $ do
    let actId = ActId "매매계약"
        voidableAct = CancellableAct actId Voidable
        validAct    = CancellableAct actId Valid
        baseFacts = CancellationFacts
          { cnfCancelled          = False
          , cnfRatified           = False
          , cnfCauseCeased        = False
          , cnfRatifierIsGuardian = False
          , cnfConstructive       = Nothing
          , cnfObjectionReserved  = False
          }

    it "§141: 취소 → Void (소급 무효)" $ do
      let j = query voidableAct baseFacts { cnfCancelled = True }
      verdict j `shouldBe` Void

    it "prior Valid + 취소 → Valid (취소 대상 아님)" $ do
      let j = query validAct baseFacts { cnfCancelled = True }
      verdict j `shouldBe` Valid

    it "Voidable + 아무 조치 없음 → Voidable (그대로)" $ do
      let j = query voidableAct baseFacts
      verdict j `shouldBe` Voidable

    it "§143: 추인 + 원인 소멸 → Valid" $ do
      let j = query voidableAct baseFacts
                { cnfRatified = True
                , cnfCauseCeased = True
                }
      verdict j `shouldBe` Valid

    it "§144①: 추인 + 원인 미소멸 → Voidable (추인 무효)" $ do
      let j = query voidableAct baseFacts
                { cnfRatified = True
                , cnfCauseCeased = False
                }
      verdict j `shouldBe` Voidable

    it "§144②: 후견인 추인 → Valid (원인 소멸 불요)" $ do
      let j = query voidableAct baseFacts
                { cnfRatified = True
                , cnfRatifierIsGuardian = True
                }
      verdict j `shouldBe` Valid

    it "§145: 법정추인 (이행) → Valid" $ do
      let j = query voidableAct baseFacts
                { cnfConstructive = Just FullOrPartialPerformance }
      verdict j `shouldBe` Valid

    it "§145: 법정추인 (강제집행) → Valid" $ do
      let j = query voidableAct baseFacts
                { cnfConstructive = Just CompulsoryExecution }
      verdict j `shouldBe` Valid

    it "§145 단서: 이의 보류 → Voidable (법정추인 안됨)" $ do
      let j = query voidableAct baseFacts
                { cnfConstructive = Just FullOrPartialPerformance
                , cnfObjectionReserved = True
                }
      verdict j `shouldBe` Voidable

    it "§141: 취소의 근거조문은 §141" $ do
      let j = query voidableAct baseFacts { cnfCancelled = True }
          steps = judgmentSteps j
      articleNumber (stepArticle (head steps)) `shouldBe` 141
```

**Step 2: Write the implementation**

```haskell
module Deontic.Civil.Cancellation () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 취소와 추인 — Cancellation & Ratification (§141, §143-§145)
--
-- CancellableAct wraps a prior Verdict from another query.
-- Only acts on Voidable inputs.
--
-- §141: 취소 → 소급 무효 (retroactive void)
-- §143: 추인 → 유효 (ratification cures)
-- §144: 추인은 취소원인 소멸 후 (법정대리인 제외)
-- §145: 법정추인 사유 (이의 보류 시 제외)
-- ═══════════════════════════════════════════════

type instance Resolvable CancellableAct = '[ConstructiveRatification, GeneralRatification, Base]

-- Base: 취소 또는 현상 유지
instance Adjudicate CancellableAct '[Base] where
  adjudicate act facts
    | caPriorVerdict act /= Voidable =
        JBase (caPriorVerdict act)
          (ArticleRef "민법" 141 Nothing)
          "취소할 수 있는 법률행위가 아니므로 취소의 대상이 되지 아니한다."
    | cnfCancelled facts =
        JBase Void
          (ArticleRef "민법" 141 Nothing)
          "취소된 법률행위는 처음부터 무효인 것으로 본다."
    | otherwise =
        JBase Voidable
          (ArticleRef "민법" 141 Nothing)
          "취소할 수 있는 법률행위로서 취소권이 행사되지 아니하였다."

-- §143-§144: 추인
instance Adjudicate CancellableAct rest
      => Adjudicate CancellableAct (GeneralRatification ': rest) where
  adjudicate act facts
    | cnfRatified facts
    , cnfCauseCeased facts || cnfRatifierIsGuardian facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev /= Valid =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 143 Nothing)
                  "취소할 수 있는 법률행위를 추인한 후에는 취소하지 못한다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)

-- §145: 법정추인
instance Adjudicate CancellableAct rest
      => Adjudicate CancellableAct (ConstructiveRatification ': rest) where
  adjudicate act facts
    | Just _ <- cnfConstructive facts
    , not (cnfObjectionReserved facts)
    , let prev = adjudicate @_ @rest act facts
    , verdict prev /= Valid =
        JOverride prev
                  Valid
                  (ArticleRef "민법" 145 Nothing)
                  "추인할 수 있는 후에 법정추인 사유가 있으므로 추인한 것으로 본다."
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
```

**Step 3: Add to cabal file**

Add `Deontic.Civil.Cancellation` to `exposed-modules` and `Deontic.Civil.CancellationSpec` to `other-modules`.

**Step 4: Run tests**

Run: `nix develop -c cabal test deontic-kr-civil`
Expected: all tests pass including the 10 new cancellation tests

**Step 5: Commit**

```bash
git add deontic-kr-civil/src/Deontic/Civil/Cancellation.hs \
        deontic-kr-civil/test/Deontic/Civil/CancellationSpec.hs \
        deontic-kr-civil/deontic-kr-civil.cabal
git commit -m "feat: add §141/§143-§145 cancellation and ratification (wrapper pattern)"
```

---

### Task 5: ConditionalAct module (§147, §150–§152)

**Files:**
- Create: `deontic-kr-civil/src/Deontic/Civil/ConditionalAct.hs`
- Create: `deontic-kr-civil/test/Deontic/Civil/ConditionalActSpec.hs`
- Modify: `deontic-kr-civil/deontic-kr-civil.cabal`

**Context:** §147 — suspensive conditions produce Pending→Valid on fulfillment, resolutive conditions produce Valid→Void. §150 — bad faith prevention/causation overrides natural condition state. §151 — illegal, impossible, and already-fulfilled conditions have special truth tables. §152 — start/end dates follow the same pattern as conditions. Uses `ConditionalFacts` record with ADTs. Three layers: `BadFaithCondition > IllegalCondition > Base`.

**Step 1: Write the test file**

```haskell
module Deontic.Civil.ConditionalActSpec (spec) where

import Test.Hspec
import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Render
import Deontic.Civil.Types
import Deontic.Civil.ConditionalAct ()

spec :: Spec
spec = do
  describe "조건부/기한부 법률행위 (§147, §150-§152)" $ do
    let actId = ActId "매매계약"
        act   = ConditionalAct actId

    -- §147 정지조건
    it "§147①: 정지조건 미성취 → Pending" $ do
      let j = query act (ConditionalFacts Suspensive CondPending Nothing)
      verdict j `shouldBe` Pending

    it "§147①: 정지조건 성취 → Valid" $ do
      let j = query act (ConditionalFacts Suspensive CondFulfilled Nothing)
      verdict j `shouldBe` Valid

    -- §147 해제조건
    it "§147②: 해제조건 미성취 → Valid" $ do
      let j = query act (ConditionalFacts Resolutive CondPending Nothing)
      verdict j `shouldBe` Valid

    it "§147②: 해제조건 성취 → Void" $ do
      let j = query act (ConditionalFacts Resolutive CondFulfilled Nothing)
      verdict j `shouldBe` Void

    -- §152 시기/종기
    it "§152①: 시기 미도래 → Pending" $ do
      let j = query act (ConditionalFacts StartDate CondPending Nothing)
      verdict j `shouldBe` Pending

    it "§152①: 시기 도래 → Valid" $ do
      let j = query act (ConditionalFacts StartDate CondFulfilled Nothing)
      verdict j `shouldBe` Valid

    it "§152②: 종기 미도래 → Valid" $ do
      let j = query act (ConditionalFacts EndDate CondPending Nothing)
      verdict j `shouldBe` Valid

    it "§152②: 종기 도래 → Void" $ do
      let j = query act (ConditionalFacts EndDate CondFulfilled Nothing)
      verdict j `shouldBe` Void

    -- §151 불법조건
    it "§151①: 불법조건 → Void" $ do
      let j = query act (ConditionalFacts Suspensive CondIllegal Nothing)
      verdict j `shouldBe` Void

    -- §151 성취불가능
    it "§151③: 정지조건 성취불가능 → Void" $ do
      let j = query act (ConditionalFacts Suspensive CondImpossible Nothing)
      verdict j `shouldBe` Void

    it "§151③: 해제조건 성취불가능 → Valid (무조건)" $ do
      let j = query act (ConditionalFacts Resolutive CondImpossible Nothing)
      verdict j `shouldBe` Valid

    -- §150 반신의행위
    it "§150①: 정지조건 + 성취방해 → Valid (성취 의제)" $ do
      let j = query act (ConditionalFacts Suspensive CondPending (Just BadFaithPrevention))
      verdict j `shouldBe` Valid

    it "§150②: 해제조건 + 성취야기 → Valid (불성취 의제)" $ do
      let j = query act (ConditionalFacts Resolutive CondFulfilled (Just BadFaithCausation))
      verdict j `shouldBe` Valid
```

**Step 2: Write the implementation**

```haskell
module Deontic.Civil.ConditionalAct () where

import Deontic.Core.Types
import Deontic.Core.Verdict
import Deontic.Core.Adjudicate
import Deontic.Core.Layer (Base, Resolvable)
import Deontic.Civil.Types

-- ═══════════════════════════════════════════════
-- 조건부/기한부 법률행위 — Conditional Acts (§147, §150-§152)
--
-- §147: 정지조건 → 성취 시 효력 발생. 해제조건 → 성취 시 효력 상실.
-- §150: 반신의행위 → 성취/불성취 의제.
-- §151: 불법조건, 기성조건, 불능조건 → 특별 규칙.
-- §152: 시기/종기 → 조건과 동일한 구조.
-- ═══════════════════════════════════════════════

type instance Resolvable ConditionalAct = '[BadFaithCondition, IllegalCondition, Base]

-- §147/§152: 조건/기한의 기본 효과
instance Adjudicate ConditionalAct '[Base] where
  adjudicate _ facts = case (condType facts, condState facts) of
    -- §147① / §152①: 정지조건/시기
    (Suspensive, CondPending)   -> pending147
    (Suspensive, CondFulfilled) -> valid147
    (StartDate,  CondPending)   -> pending152
    (StartDate,  CondFulfilled) -> valid152
    -- §147② / §152②: 해제조건/종기
    (Resolutive, CondPending)   -> valid147r
    (Resolutive, CondFulfilled) -> void147
    (EndDate,    CondPending)   -> valid152e
    (EndDate,    CondFulfilled) -> void152
    -- impossible/illegal은 IllegalCondition 레이어에서 처리;
    -- Base에서는 Pending으로 fallback
    (_, CondImpossible) -> pending147
    (_, CondIllegal)    -> pending147
    where
      pending147 = JBase Pending (ArticleRef "민법" 147 (Just 1))
        "정지조건이 성취되지 아니하여 효력이 발생하지 아니한다."
      valid147 = JBase Valid (ArticleRef "민법" 147 (Just 1))
        "정지조건이 성취하여 효력이 생긴다."
      valid147r = JBase Valid (ArticleRef "민법" 147 (Just 2))
        "해제조건이 성취되지 아니하여 효력이 존속한다."
      void147 = JBase Void (ArticleRef "민법" 147 (Just 2))
        "해제조건이 성취하여 효력을 잃는다."
      pending152 = JBase Pending (ArticleRef "민법" 152 (Just 1))
        "시기가 도래하지 아니하여 효력이 발생하지 아니한다."
      valid152 = JBase Valid (ArticleRef "민법" 152 (Just 1))
        "시기가 도래하여 효력이 생긴다."
      valid152e = JBase Valid (ArticleRef "민법" 152 (Just 2))
        "종기가 도래하지 아니하여 효력이 존속한다."
      void152 = JBase Void (ArticleRef "민법" 152 (Just 2))
        "종기가 도래하여 효력을 잃는다."

-- §151: 불법조건, 기성조건, 불능조건
instance Adjudicate ConditionalAct rest
      => Adjudicate ConditionalAct (IllegalCondition ': rest) where
  adjudicate act facts = case condState facts of
    CondIllegal ->
      JOverride (adjudicate @_ @rest act facts)
                Void
                (ArticleRef "민법" 151 (Just 1))
                "조건이 선량한 풍속 기타 사회질서에 위반한 것인 때에는 그 법률행위는 무효로 한다."
    CondImpossible -> case condType facts of
      Suspensive ->
        JOverride (adjudicate @_ @rest act facts)
                  Void
                  (ArticleRef "민법" 151 (Just 3))
                  "조건이 성취할 수 없는 것인 경우에 정지조건이면 그 법률행위는 무효로 한다."
      StartDate ->
        JOverride (adjudicate @_ @rest act facts)
                  Void
                  (ArticleRef "민법" 151 (Just 3))
                  "시기가 도래할 수 없는 것인 경우 그 법률행위는 무효로 한다."
      Resolutive ->
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 151 (Just 3))
                  "조건이 성취할 수 없는 것인 경우에 해제조건이면 조건 없는 법률행위로 한다."
      EndDate ->
        JOverride (adjudicate @_ @rest act facts)
                  Valid
                  (ArticleRef "민법" 151 (Just 3))
                  "종기가 도래할 수 없는 것인 경우 기한 없는 법률행위로 한다."
    _ -> JDelegate (adjudicate @_ @rest act facts)

-- §150: 반신의행위
instance Adjudicate ConditionalAct rest
      => Adjudicate ConditionalAct (BadFaithCondition ': rest) where
  adjudicate act facts = case condBadFaith facts of
    Just BadFaithPrevention ->
      -- 성취 의제: CondPending → CondFulfilled로 재평가
      let deemedFacts = facts { condState = CondFulfilled, condBadFaith = Nothing }
          deemedResult = query act deemedFacts
      in JOverride (adjudicate @_ @rest act facts)
                   (verdict deemedResult)
                   (ArticleRef "민법" 150 (Just 1))
                   "조건의 성취로 인하여 불이익을 받을 당사자가 신의성실에 반하여 조건의 성취를 방해한 때에는 상대방은 그 조건이 성취한 것으로 주장할 수 있다."
    Just BadFaithCausation ->
      -- 불성취 의제: CondFulfilled → CondPending으로 재평가
      let deemedFacts = facts { condState = CondPending, condBadFaith = Nothing }
          deemedResult = query act deemedFacts
      in JOverride (adjudicate @_ @rest act facts)
                   (verdict deemedResult)
                   (ArticleRef "민법" 150 (Just 2))
                   "조건의 성취로 인하여 이익을 받을 당사자가 신의성실에 반하여 조건을 성취시킨 때에는 상대방은 그 조건이 성취하지 아니한 것으로 주장할 수 있다."
    Nothing ->
      JDelegate (adjudicate @_ @rest act facts)
```

**Step 3: Add to cabal file**

Add `Deontic.Civil.ConditionalAct` to `exposed-modules` and `Deontic.Civil.ConditionalActSpec` to `other-modules`.

**Step 4: Run tests**

Run: `nix develop -c cabal test deontic-kr-civil`
Expected: all tests pass including the 13 new conditional act tests

**Step 5: Commit**

```bash
git add deontic-kr-civil/src/Deontic/Civil/ConditionalAct.hs \
        deontic-kr-civil/test/Deontic/Civil/ConditionalActSpec.hs \
        deontic-kr-civil/deontic-kr-civil.cabal
git commit -m "feat: add §147/§150-§152 conditional acts (suspensive, resolutive, bad faith, illegal)"
```

---

### Task 6: Update Deontic.Civil re-export module and docs

**Files:**
- Modify: `deontic-kr-civil/src/Deontic/Civil.hs`
- Modify: `deontic-kr-civil/src/Deontic/Civil/Types.hs` (update coverage table in Deontic.Civil)

**Step 1: Add new modules to Deontic.Civil re-exports**

Add to the export list and imports in `deontic-kr-civil/src/Deontic/Civil.hs`:

```haskell
  , module Deontic.Civil.AgencyRemedies
  , module Deontic.Civil.Invalidity
  , module Deontic.Civil.Cancellation
  , module Deontic.Civil.ConditionalAct
```

And add imports:
```haskell
import Deontic.Civil.AgencyRemedies ()
import Deontic.Civil.Invalidity ()
import Deontic.Civil.Cancellation ()
import Deontic.Civil.ConditionalAct ()
```

**Step 2: Update coverage table in the Deontic.Civil module haddock**

Add to the 총칙 section:
```
-- AgencyRemedies     §134-135   AgencyWithdrawalAct   '[CounterpartyKnowledge, Base]       상대방 악의 면책
--                               AgentLiabilityAct     '[Proviso, Base]                     대리인 면책
-- Invalidity         §137-139   PartialInvalidityAct  '[Conversion, HypotheticalIntent, Base] 일부무효·전환·추인
-- Cancellation       §141-145   CancellableAct        '[ConstructiveRatification, GeneralRatification, Base] wrapper pattern
-- ConditionalAct     §147-152   ConditionalAct        '[BadFaithCondition, IllegalCondition, Base] 정지/해제조건·시기/종기
```

**Step 3: Build and test**

Run: `nix develop -c cabal test deontic-kr-civil`
Expected: all ~202 tests pass

**Step 4: Commit**

```bash
git add deontic-kr-civil/src/Deontic/Civil.hs
git commit -m "docs: update Deontic.Civil coverage table with §134-§152"
```
