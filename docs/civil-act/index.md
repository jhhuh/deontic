# Korean Civil Act (민법) Encoding

The `deontic-kr-civil` package encodes 35+ articles of the Korean Civil Act
across 15 modules, with 166 tests including case studies based on actual
대법원 (Supreme Court) precedents.

## Coverage by 편(篇)

### 총칙 General Provisions (7 modules)

| Module | Articles | Act Type | Pattern |
|--------|----------|----------|---------|
| [Persons](general.md#5-미성년자의-법률행위) | §5 | `MinorAct` | 단서 override |
| [Acts](general.md#103-110-법률행위) | §103-110 | `JuristicAct`, `ShamAct`, `MistakeAct`, `FraudAct` | 3-layer stack |
| [Agency](general.md#114-132-대리) | §114-132 | `AuthAgencyAct`, `UnauthAgencyAct` | 표현대리·추인 |
| [Rescission](general.md#146-취소의-제척기간) | §146 | `RescissionAct` | 제척기간 (calendar year) |

### 물권법 Property Law (4 modules)

| Module | Articles | Act Type | Pattern |
|--------|----------|----------|---------|
| [Possession](property.md#197-200-점유-추정) | §197, §200 | `PossessionAct` | Rebuttable presumption |
| [PropertyTransfer](property.md#186-188-물권변동) | §186-188 | `PropertyTransferAct` | Lex specialis (§187) |
| [CoOwnership](property.md#264-공유물의-처분) | §264 | `CoOwnershipAct` | ∀ quantification |
| [AcqPrescription](property.md#245-취득시효) | §245 | `AcqPrescriptionAct` | Graduated override |

### 채권법 Obligations (4 modules)

| Module | Articles | Act Type | Pattern |
|--------|----------|----------|---------|
| [Prescription](obligations.md#162-174-소멸시효) | §162-174 | `PrescriptionAct` | Temporal (calendar year) |
| [DefaultObligation](obligations.md#387-390-채무불이행) | §387-390 | `DefaultAct` | Verdict-conditional |
| [SaleWarranty](obligations.md#580-582-하자담보) | §580-582 | `WarrantyAct` | Verdict-conditional |
| [Lease](obligations.md#618-640-임대차) | §618-640 | `LeaseAct` | Multi-condition override |

### 불법행위 Torts (1 module)

| Module | Articles | Act Type | Pattern |
|--------|----------|----------|---------|
| [Tort](torts.md) | §750, §396 | `TortAct` | Multi-element + verdict-conditional |

## Test Structure

| Test Suite | Count | Description |
|-----------|-------|-------------|
| Unit tests (per-module) | ~90 | Each module's Adjudicate instances |
| `CaseSpec` | ~12 | Basic integration tests |
| `CaseStudySpec` | 9 | End-to-end multi-issue dispute |
| `RealCasesSpec` | 45 | Based on actual 대법원 판례 |
| New module tests | 48 | §146, §186-188, §245, §387-390, §580-582, §618-640 |
| **Total** | **166** | |
