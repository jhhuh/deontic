# 총칙 General Provisions

## §5 미성년자의 법률행위

**Module:** `Deontic.Civil.Persons`

> 미성년자가 법률행위를 함에는 법정대리인의 동의를 얻어야 한다.
> 그러나 권리만을 얻거나 의무만을 면하는 행위는 그러하지 아니하다.

**Layer stack:** `'[Proviso, Base]`

```haskell
-- Base (§5① 본문): consent required
instance Adjudicate MinorAct '[Base] where
  adjudicate act facts
    | HasConsent ... `Set.member` facts = JBase Valid ...
    | otherwise                        = JBase Voidable ...

-- Proviso (§5① 단서): rights-only acts exempt
instance Adjudicate MinorAct rest
      => Adjudicate MinorAct (Proviso ': rest) where
  adjudicate act facts
    | MerelyAcquiresRight `Set.member` facts =
        JOverride (adjudicate @_ @rest act facts) Valid ...
    | otherwise =
        JDelegate (adjudicate @_ @rest act facts)
```

This is the simplest defeasibility pattern: a base rule with a single
proviso that can override it.

## §103-110 법률행위

**Module:** `Deontic.Civil.Acts`

A 3-layer stack handles multiple grounds of invalidity:

**Layer stack:** `'[SpecialRule, Proviso, Base]`

| Layer | Articles | Logic |
|-------|----------|-------|
| Base | §103-104 | `ContraBonorsMores` or `ExploitativeAct` → `Void` |
| Proviso | §107-108 | `HiddenIntention` + `CounterpartyKnew` → `Void`; `BonaFideThirdParty` protects |
| SpecialRule | §109-110 | Mistake → `Voidable` (unless `GrossNegligence`); Fraud → `Voidable` |

The same `JuristicAct` type handles §103, §104, and §107 through the
`CivilFact` set. Separate act types (`ShamAct`, `MistakeAct`, `FraudAct`)
model §108, §109, and §110 with their own stacks.

### §108 통정허위표시

**Act type:** `ShamAct` — **Layers:** `'[Proviso, Base]`

- Base: sham → `Void` (between parties)
- Proviso: `BonaFideThirdParty` → `Valid` (third party protected)

### §109 착오

**Act type:** `MistakeAct` — **Layers:** `'[Proviso, Base]`

- Base: mistake → `Voidable`
- Proviso: `GrossNegligence` → `Valid` (no rescission if grossly negligent)

### §110 사기·강박

**Act type:** `FraudAct` — **Layers:** `'[Proviso, Base]`

- Base: fraud → `Voidable`
- Proviso: `ThirdPartyFraud` without `CounterpartyKnewFraud` → `Valid`

## §114-132 대리

**Module:** `Deontic.Civil.Agency`

### §114, §118 유권대리

**Act type:** `AuthAgencyAct` — **Layers:** `'[Proviso, Base]`

- Base: authorized agency → `Valid`
- Proviso: `SelfDealing` → `Voidable` (§118 자기계약 금지)

### §125-132 무권대리

**Act type:** `UnauthAgencyAct` — **Layers:** `'[ApparentAuth, Ratification, Base]`

This is the most complex layer stack in 총칙:

| Layer | Article | Logic |
|-------|---------|-------|
| Base | §130 | No authority → `Pending` (awaiting ratification) |
| Ratification | §132 | `Ratified` ∈ facts → override to `Valid` |
| ApparentAuth | §125-129 | `IndicatedAuthority`/`ExceededScope`/`AuthorityExpired` → override to `Valid` |

The 3-layer stack means: first check apparent authority (§125-129), then
check ratification (§132), then apply the base rule (§130). If apparent
authority exists, it overrides everything below. If not, check ratification.
If neither, the act remains `Pending`.

## §146 취소의 제척기간

**Module:** `Deontic.Civil.Rescission`

> 취소권은 추인할 수 있는 날로부터 3년 내에,
> 법률행위가 있은 날로부터 10년 내에 행사하여야 한다.

**Act type:** `RescissionAct` — **Layers:** `'[Base]`

```haskell
data RescissionFacts = RescissionFacts
  { rfKnowledgeDate :: Day  -- 취소원인을 안 날
  , rfActDate       :: Day  -- 법률행위가 있은 날
  , rfCurrentDate   :: Day  -- 판단 시점
  }
```

A single-layer temporal check with two conditions:

1. `addGregorianYearsClip 10 rfActDate <= rfCurrentDate` → `Void` (10년 절대적 제척기간)
2. `addGregorianYearsClip 3 rfKnowledgeDate <= rfCurrentDate` → `Void` (3년 상대적 제척기간)
3. Otherwise → `Valid` (취소권 존속)

Uses `Data.Time.Day` with `addGregorianYearsClip` for proper §157 calendar
year computation.
