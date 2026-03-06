# 채권법 Obligations

## §162-174 소멸시효

**Module:** `Deontic.Civil.Prescription`

> §162①: 채권은 10년간 행사하지 아니하면 소멸시효가 완성한다.
>
> §174: 시효가 중단된 때에는 중단까지에 경과한 시효기간은 이를 산입하지 아니하고
> 중단사유가 종료한 때로부터 새로이 진행한다.

**Act type:** `PrescriptionAct` — **Layers:** `'[Interruption, Expiration]`

```haskell
data PrescriptionFacts = PrescriptionFacts
  { pfClaimDate     :: Day        -- 채권 발생일
  , pfCurrentDate   :: Day        -- 판단 시점
  , pfPeriodYears   :: Int        -- 소멸시효기간 (년)
  , pfInterruptedOn :: Maybe Day  -- 중단 시점
  }
```

| Layer | Article | Logic |
|-------|---------|-------|
| Expiration (base) | §162 | `claimDate + period <= currentDate` → `Void` |
| Interruption (override) | §174 | `interruptionDate + period > currentDate` → override to `Valid` |

The interruption layer recalculates the period from the interruption date.
If the new elapsed time is within the period, the prescription is not yet
complete (override to `Valid`). Otherwise, the expiration base verdict
stands (delegate).

### Calendar Year Computation

All date comparisons use `addGregorianYearsClip`:

```haskell
addGregorianYearsClip (toInteger (pfPeriodYears facts)) (pfClaimDate facts)
  <= pfCurrentDate facts
```

This implements §157's "역에 의한 계산" (calendar computation), correctly
handling leap years.

## §387-390 채무불이행

**Module:** `Deontic.Civil.DefaultObligation`

> §387: 채무자가 이행기에 이행하지 않으면 이행지체의 책임이 있다.
>
> §390: 채무불이행이 채무자의 고의나 과실에 의한 것이 아니면 면책.
> 채권자에게도 과실이 있으면 감경.

**Act type:** `DefaultAct` — **Layers:** `'[CreditorDefense, Base]`

```haskell
data DefaultFacts = DefaultFacts
  { dfPerformanceDue :: Bool  -- 이행기 도래
  , dfNonPerformance :: Bool  -- 불이행
  , dfDebtorFault    :: Bool  -- 채무자 귀책사유
  , dfImpossible     :: Bool  -- 이행불능
  , dfCreditorFault  :: Bool  -- 채권자 과실
  }
```

| Layer | Article | Logic |
|-------|---------|-------|
| Base | §387-389 | Due + non-performance + debtor fault → `Void`; no fault → `Valid` |
| CreditorDefense | §390 | Creditor fault + base `Void` → override to `Voidable` (reduced liability) |

This uses the **verdict-conditional override** pattern: the `CreditorDefense`
layer only fires when the base verdict is `Void` (liability established).
If there's no liability to begin with, creditor fault is irrelevant.

```haskell
instance ... => Adjudicate DefaultAct (CreditorDefense ': rest) where
  adjudicate act facts
    | dfCreditorFault facts
    , let prev = adjudicate @_ @rest act facts
    , verdict prev == Void =      -- only override if liability exists
        JOverride prev Voidable ...
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
```

## §580-582 하자담보

**Module:** `Deontic.Civil.SaleWarranty`

> §580①: 매매의 목적물에 하자가 있는 때에는 매수인은 계약의 해제 또는
> 손해배상을 청구할 수 있다.
>
> §580②: 그러나 매수인이 하자 있는 것을 알았거나 과실로 인하여
> 이를 알지 못한 때에는 그러하지 아니하다.
>
> §582: 매수인이 사실을 안 날로부터 6월 내에 행사하여야 한다.

**Act type:** `WarrantyAct` — **Layers:** `'[BuyerKnowledge, Base]`

```haskell
data WarrantyFacts = WarrantyFacts
  { wfDefectExists   :: Bool  -- 하자 존재
  , wfSignificant    :: Bool  -- 중대한 하자
  , wfBuyerKnew      :: Bool  -- 매수인 악의/과실
  , wfNotifiedInTime :: Bool  -- 6월 내 통지
  }
```

| Layer | Article | Logic |
|-------|---------|-------|
| Base | §580①, §582 | Defect + timely notice → `Voidable`; significant defect → `Void`; no defect or late notice → `Valid` |
| BuyerKnowledge | §580② | Buyer knew + base ≠ `Valid` → override to `Valid` (no warranty) |

Another verdict-conditional override: buyer's knowledge only matters
when there is actually warranty liability to defend against.

## §618-640 임대차

**Module:** `Deontic.Civil.Lease`

> §618: 임대차는 목적물을 사용·수익하게 하고 차임을 지급하는 약정.
>
> §639: 임대차기간 만료 후 임차인이 사용을 계속하고 임대인이 이의를
> 하지 아니한 때에는 동일한 조건으로 다시 임대차한 것으로 본다.
>
> §640: 임차인의 차임연체액이 2기의 차임액에 달하면 해지 가능.

**Act type:** `LeaseAct` — **Layers:** `'[RenewalRight, Base]`

```haskell
data LeaseFacts = LeaseFacts
  { lfValidContract  :: Bool  -- 유효한 계약
  , lfRentPaid       :: Bool  -- 차임 지급
  , lfPeriodExpired  :: Bool  -- 기간 만료
  , lfContinuedUse   :: Bool  -- 계속 사용
  , lfNoObjection    :: Bool  -- 이의 없음
  , lfTwoRentsLate   :: Bool  -- 2기 연체
  }
```

| Layer | Article | Logic |
|-------|---------|-------|
| Base | §618, §640 | Invalid contract or 2-rent arrears → `Void`; expired → `Void`; otherwise → `Valid` |
| RenewalRight | §639 | Expired + continued use + no objection + no arrears → override to `Valid` |

This is a **multi-condition override**: all four conditions must hold for
implicit renewal to apply. Notably, 2-rent arrears blocks renewal even
when all other conditions are met (arrears is checked in the Base layer
*and* in the RenewalRight guard).
