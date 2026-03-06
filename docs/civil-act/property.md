# 물권법 Property Law

## §197, §200 점유 추정

**Module:** `Deontic.Civil.Possession`

> §197: 점유자는 소유의 의사로 선의, 평온 및 공연하게 점유한 것으로 추정한다.
>
> §200: 점유자가 점유물에 대하여 행사하는 권리는 적법하게 보유하는 것으로 추정한다.

**Act type:** `PossessionAct` — **Layers:** `'[Rebuttal, Presumption]`

This module demonstrates the **rebuttable presumption** pattern:

| Layer | Role | Logic |
|-------|------|-------|
| Presumption (base) | Default: presumption holds | Always → `JBase Valid` |
| Rebuttal (override) | Counter-evidence defeats presumption | `BadFaith`/`ViolentPossession`/`ClandestinePossession`/`NoOwnershipIntent` → `JOverride Voidable` |

The key insight: **absence of rebuttal facts causes delegation**. When no
rebuttal evidence is presented, the Rebuttal layer delegates to the
Presumption layer, and the default holds. This is a closed-world assumption
encoded in open-world machinery.

```haskell
-- Presumption (base): always Valid
instance Adjudicate PossessionAct '[Presumption] where
  adjudicate _ _ = JBase Valid ...

-- Rebuttal (override): check for counter-evidence
instance Adjudicate PossessionAct rest
      => Adjudicate PossessionAct (Rebuttal ': rest) where
  adjudicate act facts
    | BadFaith `Set.member` facts = JOverride prev Voidable ...
    | ...
    | otherwise = JDelegate prev  -- no rebuttal → presumption holds
```

## §186-188 물권변동

**Module:** `Deontic.Civil.PropertyTransfer`

> §186: 부동산에 관한 법률행위로 인한 물권의 득실변경은 등기하여야 그 효력이 생긴다.
>
> §187: 상속, 공용징수, 판결, 경매 기타 법률의 규정에 의한 부동산물권취득은 등기를 요하지 아니한다.
>
> §188①: 동산에 관한 물권의 양도는 그 동산을 인도하여야 효력이 생�다.

**Act type:** `PropertyTransferAct` — **Layers:** `'[FormException, Base]`

This demonstrates the **lex specialis** pattern:

| Layer | Article | Logic |
|-------|---------|-------|
| Base | §186, §188 | Real property needs registration; movables need delivery |
| FormException | §187 | Inheritance/court order/auction/expropriation bypass registration |

```haskell
-- Base: formality requirements
instance Adjudicate PropertyTransferAct '[Base] where
  adjudicate _ facts
    | IsRealProperty ∈ facts, HasRegistration ∈ facts = JBase Valid ...
    | IsRealProperty ∈ facts                         = JBase Void ...
    | IsMovableProperty ∈ facts, HasDelivery ∈ facts = JBase Valid ...
    | IsMovableProperty ∈ facts                      = JBase Void ...

-- FormException: §187 bypasses registration for certain acquisitions
instance ... => Adjudicate PropertyTransferAct (FormException ': rest) where
  adjudicate act facts
    | IsRealProperty ∈ facts
    , any (`Set.member` facts)
        [ByInheritance, ByCourtOrder, ByPublicAuction, ByExpropriation] =
        JOverride prev Valid ...  -- no registration needed
    | otherwise = JDelegate prev
```

## §264 공유물의 처분

**Module:** `Deontic.Civil.CoOwnership`

> 공유물의 처분, 변경은 공유자 전원의 동의가 있어야 한다.

**Act type:** `CoOwnershipAct` — **Layers:** `'[Base]`

Demonstrates **universal quantification** without framework changes:

```haskell
data CoOwnershipFacts = CoOwnershipFacts
  { cofOwners    :: [PersonId]      -- all co-owners
  , cofConsented :: Set PersonId    -- those who consented
  }

instance Adjudicate CoOwnershipAct '[Base] where
  adjudicate _ facts
    | all (`Set.member` cofConsented facts) (cofOwners facts) =
        JBase Valid ...   -- ∀ owner ∈ owners, owner ∈ consented
    | otherwise =
        JBase Void ...    -- at least one owner didn't consent
```

The `all` function + `Set.member` implements the universal quantifier
$\forall$ using standard Haskell.

## §245 취득시효

**Module:** `Deontic.Civil.AcquisitivePrescription`

> §245①: 20년간 소유의 의사로 평온, 공연하게 부동산을 점유하는 자는
> 등기함으로써 그 소유권을 취득한다.
>
> §245②: 부동산의 소유자로 등기한 자가 10년간 소유의 의사로 평온, 공연하게
> 선의이며 과실 없이 그 부동산을 점유한 때에는 소유권을 취득한다.

**Act type:** `AcqPrescriptionAct` — **Layers:** `'[ShortPrescription, Base]`

Demonstrates **graduated override** — the override layer has stricter
requirements but a shorter period:

```haskell
data AcqPrescFacts = AcqPrescFacts
  { apfStartDate      :: Day   -- 점유 개시일
  , apfCurrentDate    :: Day   -- 판단 시점
  , apfGoodFaith      :: Bool  -- 선의
  , apfNoNegligence   :: Bool  -- 무과실
  , apfPeaceful       :: Bool  -- 평온
  , apfPublic         :: Bool  -- 공연
  , apfSelfPossession :: Bool  -- 자주점유
  }
```

| Layer | Article | Period | Extra Requirements |
|-------|---------|--------|--------------------|
| Base | §245① | 20 years | Self-possession + peaceful + public |
| ShortPrescription | §245② | 10 years | All of above + good faith + no negligence |

Uses `addGregorianYearsClip` for proper calendar year computation per §157.
