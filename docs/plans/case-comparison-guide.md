# Case Comparison Guide: Colorizing Framework Output vs. Court Reasoning

> **For Claude:** This is a standalone task. You do NOT need project context.
> You only need the framework output file and access to Korean legal databases.

## Goal

Create a side-by-side comparison page (`docs/civil-act/case-comparison.md`)
that places our framework's judgment output next to actual Korean Supreme
Court (대법원) reasoning, with color-coded semantic matching.

## Inputs

1. **Framework output**: `docs/civil-act/case-demonstrations.md` — contains
   actual rendered output for 7 cases, each with 인정사실, fact mapping,
   and 프레임워크 판결문.

2. **Actual court reasoning**: For each case, you need the actual 대법원
   판시사항 (court's holding). Sources:
   - Case numbers are listed in the demonstration file (e.g., 대법원 2005다71659)
   - Search on law.go.kr or use your training data for the standard holdings
   - If exact text is unavailable, reconstruct the standard legal reasoning
     structure from the cited articles and established Korean legal doctrine
   - **Mark reconstructed reasoning clearly** with "(판시 재구성)" so readers
     know it's not verbatim

## Output Format

For each case, create an HTML table with two columns using mkdocs-material
compatible HTML (the site uses `md_in_html` extension):

```html
<table>
<thead>
<tr><th width="50%">프레임워크 출력</th><th width="50%">대법원 판시</th></tr>
</thead>
<tbody>
<tr style="background: #COLOR;">
<td>Framework sentence</td>
<td>Court sentence</td>
</tr>
</tbody>
</table>
```

## Color Code

Apply these background colors to each `<tr>`:

| Color | Hex | Meaning | When to use |
|---|---|---|---|
| Green | `#d4edda` | **Semantic match** | Same legal conclusion AND same article cited |
| Yellow | `#fff3cd` | **Partial match** | Same conclusion but different reasoning depth, or same article but phrased very differently |
| Red | `#f8d7da` | **Semantic mismatch** | Different conclusion or wrong article |
| Gray | `#e2e3e5` | **Present in one side only** | Court adds reasoning the framework doesn't produce, or vice versa |

## Row Alignment Rules

Align rows by **semantic function**, not by sentence order:

1. **Verdict row**: The final conclusion line. Framework: "판단: 본 법률행위는 X"
   vs. Court: the holding sentence.
2. **Base rule row**: The first article cited. Framework: "민법 제X조에 의하면..."
   vs. Court's citation of the same article.
3. **Override row**: If the framework shows an override ("에 의하여 이를 번복하면"),
   match it to the court's exception/proviso reasoning.
4. **Policy/value row**: Court statements about legislative purpose, burden of
   proof, or policy considerations that have no framework counterpart → gray,
   framework cell says "(해당 없음)".
5. **Conclusion row**: Framework: "따라서, 본 법률행위는 X" vs. Court's final
   disposition.

## Per-Case Instructions

### Case 1: 대법원 2005다71659 (미성년자 신용구매)
- Look for: §5① holding about 미성년자 보호
- Expected: verdict match (취소 가능), article match (§5①)
- Court likely adds: 미성년자 보호 > 거래 안전 (gray row)

### Case 2a: 대법원 94다12074 (통정허위표시 당사자 간)
- Look for: §108① holding about 통정허위표시 무효
- Expected: verdict match (무효), article match (§108①)

### Case 2b: 대법원 2019다280375 (통정허위표시 선의 제3자)
- Look for: §108②, 선의 추정, 입증책임
- Expected: verdict match (유효), override match (§108② 번복)
- Court likely adds: 입증책임 분배 설시 (gray row)

### Case 3: 대법원 2013다49794 (착오 + 중과실)
- Look for: §109① 본문 + 단서
- Expected: verdict match (유효), override match (중과실 → 취소 불가)
- Court likely adds: 중대한 과실의 판단기준 정의 (gray row)

### Case 4: 대법원 93다47745 (시효중단)
- Look for: §162①, §168, §174
- Expected: verdict match (유효/시효 미완성), override match (시효중단)
- Yellow row likely: framework doesn't show computed dates, court does

### Case 5: 교통사고 + 과실상계
- Look for: §750, §763→§396
- Expected: verdict match (책임 감경), override match (과실상계)
- Yellow row likely: framework shows Voidable (qualitative), court shows
  specific percentage (quantitative)

### Case 6: 복합 쟁점
- This is a constructed case study, not a single real case
- Compare each sub-issue separately, then the combined verdict
- Court comparison is hypothetical — mark all court cells "(판시 재구성)"

### Case 7: 대법원 98다60828 (제3자 사기)
- Look for: §110①, §110②
- Expected: verdict match (유효), override match (제3자 사기 + 상대방 선의)
- Court likely adds: "동일시할 수 있는 자" 범위 설시 (gray row)

## Summary Section

After all cases, add an observations section with three colored boxes:

```html
<div style="background: #d4edda; padding: 1em; border-radius: 5px; margin-bottom: 1em;">
<strong>What matches well</strong>
<ol>
<li>...</li>
</ol>
</div>

<div style="background: #fff3cd; padding: 1em; border-radius: 5px; margin-bottom: 1em;">
<strong>What doesn't match (by design)</strong>
<ol>
<li>...</li>
</ol>
</div>

<div style="background: #f8d7da; padding: 1em; border-radius: 5px; margin-bottom: 1em;">
<strong>What doesn't match (potential improvement)</strong>
<ol>
<li>...</li>
</ol>
</div>
```

Categorize observed differences:
- **By design**: value judgments, burden of proof, quantitative calculations,
  procedural law — these are outside the framework's scope
- **Potential improvement**: missing date display, single ArticleRef limitation,
  verdict terminology mismatch ("취소할 수 있다" for non-cancellation contexts)

## Quality Checks

Before submitting:

1. Every framework output cell must be **verbatim** from `case-demonstrations.md`
   — do not modify or paraphrase the framework output
2. Every court reasoning cell must cite the source: exact 판례 number if from
   actual opinion, or "(판시 재구성)" if reconstructed
3. Color coding must be consistent — same semantic relationship = same color
4. The file must render correctly in mkdocs-material (test with `mkdocs serve`
   if available)
5. It's OK for some cases to show mismatches — the point is honest comparison,
   not cherry-picking matches
