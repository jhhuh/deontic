# API Reference

## Haddock Documentation

Full API documentation is generated from the Haskell source using Haddock:

- [**deontic-core**](haddock/deontic-core/index.html) — Core framework
- [**deontic-kr-civil**](haddock/deontic-kr-civil/index.html) — Korean Civil Act
- [**deontic-de-bgb**](haddock/deontic-de-bgb/index.html) — German BGB fragment

## Quick Reference

### Core Types

| Type | Module | Description |
|------|--------|-------------|
| `PersonId` | `Deontic.Core.Types` | Legal person identifier |
| `ActId` | `Deontic.Core.Types` | Legal act identifier |
| `ArticleRef` | `Deontic.Core.Types` | Statutory article reference |
| `Verdict` | `Deontic.Core.Verdict` | `Valid \| Void \| Voidable \| Pending` |
| `Judgment layers` | `Deontic.Core.Adjudicate` | Proof term GADT |
| `SomeJudgment` | `Deontic.Core.Adjudicate` | Existentially wrapped judgment |

### Core Functions

| Function | Type | Description |
|----------|------|-------------|
| `query` | `Adjudicate act (Resolvable act) => act -> Facts act -> Judgment (Resolvable act)` | Main entry point |
| `verdict` | `Judgment layers -> Verdict` | Extract verdict from judgment |
| `verdictMeet` | `Verdict -> Verdict -> Verdict` | Combine two verdicts (semilattice meet) |
| `combineVerdicts` | `[SomeJudgment] -> Verdict` | Combine multiple independent judgments |
| `judgmentSteps` | `Judgment layers -> [Step]` | Extract reasoning chain |
| `renderJudgment` | `Renderer r => r -> Judgment layers -> Text` | Render as text |

### Core Type Families

| Family | Kind | Description |
|--------|------|-------------|
| `Facts act` | `Type` | Evidence structure for an act type |
| `Resolvable act` | `[Type]` | Layer stack for an act type |

### Layer Tokens

| Token | Package | Meaning |
|-------|---------|---------|
| `Base` | core | General rule (원칙) |
| `Proviso` | core | Exception (단서) |
| `SpecialRule` | core | Lex specialis (특칙) |
| `Ratification` | kr-civil | 추인 (§130, §132) |
| `ApparentAuth` | kr-civil | 표현대리 (§125-129) |
| `Presumption` | kr-civil | 추정 (default rule) |
| `Rebuttal` | kr-civil | 반증 (rebuttal) |
| `Expiration` | kr-civil | 시효만료 (§162) |
| `Interruption` | kr-civil | 시효중단 (§168, §174) |
| `ContributoryNeg` | kr-civil | 과실상계 (§763→§396) |
| `FormException` | kr-civil | 등기예외 (§187) |
| `ShortPrescription` | kr-civil | 단기시효 (§245②) |
| `CreditorDefense` | kr-civil | 채권자과실 (§390) |
| `BuyerKnowledge` | kr-civil | 매수인악의 (§580②) |
| `RenewalRight` | kr-civil | 묵시적갱신 (§639) |
