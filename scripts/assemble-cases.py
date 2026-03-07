#!/usr/bin/env python3
"""Assemble case-demonstrations.md from per-case component files.

Each case directory contains:
  - case.yaml: metadata, identity, facts, eval expression
  - fulltext.md: full court text (optional — hypothetical cases lack this)
  - summary.md: court text summary for left column
  - framework-output.md: generated framework output for right column

Usage:
  python3 scripts/assemble-cases.py           # English (default)
  python3 scripts/assemble-cases.py --ko      # Korean
"""
import os
import sys
import yaml

SCRIPT_DIR = os.path.dirname(__file__)
CASES_DIR = os.path.join(SCRIPT_DIR, "..", "docs", "civil-act", "cases")
TEMPLATES_DIR = os.path.join(SCRIPT_DIR, "templates")

# Order of cases in the final document
CASE_ORDER = [
    "2005다71659",
    "94다12074",
    "2019다280375",
    "2013다49794",
    "98다60828",
    "91다32190",
]

CSS = """\
<style>
.comparison { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; border: 1px solid var(--md-default-fg-color--lightest); }
.comparison > div { padding: 0.5rem 1rem; }
.comparison > div:first-child { border-right: 1px solid var(--md-default-fg-color--lightest); }
.comparison-header { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; background: var(--md-default-fg-color--lightest); font-weight: bold; padding: 0.5rem 1rem; }
</style>
"""

# Per-language labels for case sections
LABELS = {
    "en": {
        "case_prefix": "Case",
        "identity": "Identity",
        "fact_translation": "Fact Translation",
        "judgment_comparison": "Judgment Comparison",
        "fulltext_link": "판결문 전문",
    },
    "ko": {
        "case_prefix": "사례",
        "identity": "당사자",
        "fact_translation": "사실관계 번역",
        "judgment_comparison": "판결 비교",
        "fulltext_link": "판결문 전문",
    },
}


def load_template(name: str, lang: str) -> str:
    """Load a template file, with language suffix for non-English."""
    if lang == "en":
        path = os.path.join(TEMPLATES_DIR, f"{name}.md")
    else:
        path = os.path.join(TEMPLATES_DIR, f"{name}.{lang}.md")
    with open(path, "r") as f:
        return f.read()


def read_file(path: str) -> str | None:
    if os.path.isfile(path):
        with open(path, "r") as f:
            return f.read().strip()
    return None


def identity_grid(case_data: dict) -> str:
    """Build identity section as a markdown table with id, role, haskell."""
    rows = case_data.get("identity", [])
    if not rows:
        return ""
    lines = []
    lines.append("| ID | 역할 | Haskell |")
    lines.append("|:---|:-----|:--------|")
    for row in rows:
        rid = row.get("id", "")
        role = row.get("role", "")
        haskell = row.get("haskell", "")
        lines.append(f"| `{rid}` | {role} | `{haskell}` |")
    return "\n".join(lines)


def facts_grid(case_data: dict) -> str:
    """Build fact translation section as a side-by-side grid."""
    rows = case_data.get("facts", [])
    if not rows:
        return ""
    lines = []
    lines.append('<div class="comparison-header">')
    lines.append("<div>인정사실</div>")
    lines.append("<div>Haskell Encoding</div>")
    lines.append("</div>")
    lines.append('<div class="comparison" markdown>')
    lines.append("<div markdown>")
    lines.append("")
    for row in rows:
        lines.append(f"- {row['description']}")
    lines.append("")
    lines.append("</div>")
    lines.append("<div markdown>")
    lines.append("")
    for row in rows:
        lines.append(f"- `{row['haskell']}`")
    lines.append("")
    lines.append("</div>")
    lines.append("</div>")
    return "\n".join(lines)


def judgment_grid(case_data: dict, summary: str, framework: str) -> str:
    """Build judgment comparison as a side-by-side grid."""
    court = case_data.get("court") or "(판례 미매칭)"
    lines = []
    lines.append('<div class="comparison-header">')
    lines.append(f"<div>{court}</div>")
    lines.append("<div>프레임워크 출력</div>")
    lines.append("</div>")
    lines.append('<div class="comparison" markdown>')
    lines.append("<div markdown>")
    lines.append("")
    lines.append(summary)
    lines.append("")
    lines.append("</div>")
    lines.append("<div markdown>")
    lines.append("")
    lines.append(framework)
    lines.append("")
    lines.append("</div>")
    lines.append("</div>")
    return "\n".join(lines)


def match_badge(case_dir: str) -> str:
    """Read match.yaml and return a badge string, or empty if no match file."""
    match_path = os.path.join(case_dir, "match.yaml")
    if not os.path.isfile(match_path):
        return ""
    with open(match_path, "r") as f:
        data = yaml.safe_load(f)
    if not data:
        return ""
    result = data.get("match", "")
    reasoning = data.get("reasoning", "")
    if result is True or result == "true":
        icon = "&#x2705;"  # green check
        label = "일치"
    elif result == "partial":
        icon = "&#x26A0;"  # warning
        label = "부분 일치"
    else:
        icon = "&#x274C;"  # red X
        label = "불일치"
    return f"**판정**: {icon} {label} — {reasoning}"


def build_case(case_name: str, case_num: int, lang: str) -> str:
    """Build the markdown section for a single case."""
    case_dir = os.path.join(os.path.abspath(CASES_DIR), case_name)
    yaml_path = os.path.join(case_dir, "case.yaml")
    lbl = LABELS[lang]

    with open(yaml_path, "r") as f:
        case_data = yaml.safe_load(f)

    title = case_data.get("title", case_name)
    court = case_data.get("court")

    summary = read_file(os.path.join(case_dir, "summary.md")) or "(요약 없음)"
    framework = read_file(os.path.join(case_dir, "framework-output.md")) or "(프레임워크 출력 없음)"

    # Section heading
    prefix = lbl["case_prefix"]
    if court:
        heading = f"## {prefix} {case_num}: {title} ({court})"
    else:
        heading = f"## {prefix} {case_num}: {title}"

    lines = [heading, ""]

    # Link to fulltext if it exists
    has_fulltext = os.path.isfile(os.path.join(case_dir, "fulltext.md"))
    if has_fulltext and court:
        lines.append(f"[{lbl['fulltext_link']}](cases/{case_name}/fulltext.md)")
        lines.append("")

    # Match badge (only for real court cases)
    badge = match_badge(case_dir)
    if badge:
        lines.append(badge)
        lines.append("")

    # Identity grid
    lines.append(f"### {lbl['identity']}")
    lines.append("")
    lines.append(identity_grid(case_data))
    lines.append("")

    # Facts grid
    lines.append(f"### {lbl['fact_translation']}")
    lines.append("")
    lines.append(facts_grid(case_data))
    lines.append("")

    # Judgment comparison grid
    lines.append(f"### {lbl['judgment_comparison']}")
    lines.append("")
    lines.append(judgment_grid(case_data, summary, framework))
    lines.append("")

    return "\n".join(lines)


def main():
    lang = "ko" if "--ko" in sys.argv else "en"

    header = load_template("header", lang)
    pipeline = load_template("pipeline", lang)
    analysis = load_template("analysis", lang)
    appendix = load_template("appendix", lang)

    parts = [CSS, header, "\n", pipeline]
    for i, case_name in enumerate(CASE_ORDER, 1):
        case_dir = os.path.join(os.path.abspath(CASES_DIR), case_name)
        if not os.path.isdir(case_dir):
            print(f"Warning: case directory not found: {case_name}")
            continue
        parts.append(build_case(case_name, i, lang))
        parts.append("---\n")

    parts.append("\n---\n\n" + analysis)
    parts.append("\n---\n\n" + appendix)

    if lang == "en":
        output_path = os.path.join(SCRIPT_DIR, "..", "docs", "civil-act", "en-case-demonstrations.md")
    else:
        output_path = os.path.join(SCRIPT_DIR, "..", "docs", "ko", "civil-act", "case-demonstrations.md")

    output = os.path.abspath(output_path)
    with open(output, "w") as f:
        f.write("\n".join(parts))

    print(f"Assembled ({lang}): {output}")
    print(f"Cases: {len(CASE_ORDER)}")


if __name__ == "__main__":
    main()
