#!/usr/bin/env python3
"""Fetch court decision fulltext from casenote.kr and extract structured sections.

Usage:
  python3 scripts/fetch-case.py 93다47745
  python3 scripts/fetch-case.py --all          # fetch all cases with case.yaml
  python3 scripts/fetch-case.py --verify       # compare fetched vs stored
  python3 scripts/fetch-case.py --from-nix     # extract from nix case-html outpath

The --from-nix mode reads pre-fetched HTML from `nix build .#case-html`,
avoiding network access. HTML sources are sha256-pinned in nix/case-sources.nix.
"""
import os
import re
import subprocess
import sys
from html.parser import HTMLParser
from urllib.parse import quote as urlquote

import requests
import yaml

CASES_DIR = os.path.join(os.path.dirname(__file__), "..", "docs", "civil-act", "cases")


class TextExtractor(HTMLParser):
    """Extract text content from HTML, skipping scripts/styles/nav."""

    def __init__(self):
        super().__init__()
        self.parts: list[str] = []
        self.skip_depth = 0
        self.skip_tags = {"script", "style", "nav", "header", "footer", "noscript"}

    def handle_starttag(self, tag, attrs):
        if tag in self.skip_tags:
            self.skip_depth += 1
        if tag in ("p", "div", "br", "h1", "h2", "h3", "h4", "h5", "li", "tr"):
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in self.skip_tags:
            self.skip_depth = max(0, self.skip_depth - 1)

    def handle_data(self, data):
        if self.skip_depth == 0:
            self.parts.append(data)

    def get_text(self) -> str:
        return "".join(self.parts)


def fetch_case_text(case_id: str) -> str | None:
    """Fetch raw text from casenote.kr for a given case ID."""
    encoded = urlquote(f"대법원/{case_id}")
    url = f"https://casenote.kr/{encoded}"
    try:
        r = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=15)
        r.raise_for_status()
    except Exception as e:
        print(f"  Fetch error: {e}", file=sys.stderr)
        return None
    parser = TextExtractor()
    parser.feed(r.text)
    return parser.get_text()


def extract_from_html_file(html_path: str) -> str | None:
    """Extract text from a local HTML file."""
    with open(html_path, "r", encoding="utf-8") as f:
        html = f.read()
    parser = TextExtractor()
    parser.feed(html)
    return parser.get_text()


def get_nix_outpath() -> str | None:
    """Get the Nix store path for case-html, building if needed."""
    try:
        result = subprocess.run(
            ["nix", "build", ".#case-html", "--no-link", "--print-out-paths"],
            capture_output=True, text=True, timeout=120,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception as e:
        print(f"  nix build error: {e}", file=sys.stderr)
    return None


def extract_sections(raw_text: str) -> dict[str, str]:
    """Extract 주문, 판시사항, 판결요지, 이유 sections from raw text."""
    lines = raw_text.split("\n")
    sections: dict[str, list[str]] = {}
    current_section = None

    # Patterns for section headers
    section_patterns = {
        "주문": re.compile(r"^주문$"),
        "판시사항": re.compile(r"^판시사항$"),
        "판결요지": re.compile(r"^판결요지$"),
        "이유": re.compile(r"^이유$"),
        "참조조문": re.compile(r"^참조조문$"),
        "참조판례": re.compile(r"^참조판례$"),
    }

    # Sections to stop collecting at
    stop_sections = {"참조조문", "참조판례"}

    for line in lines:
        stripped = line.strip()
        if not stripped:
            if current_section and current_section not in stop_sections:
                sections.setdefault(current_section, []).append("")
            continue

        # Check if this is a section header
        matched = False
        for name, pattern in section_patterns.items():
            if pattern.match(stripped):
                current_section = name
                matched = True
                break

        if matched:
            if current_section in stop_sections:
                current_section = None  # Stop collecting
            continue

        if current_section and current_section not in stop_sections:
            sections.setdefault(current_section, []).append(stripped)

    # Clean up: remove trailing empty lines
    result = {}
    for name, content_lines in sections.items():
        while content_lines and not content_lines[-1]:
            content_lines.pop()
        while content_lines and not content_lines[0]:
            content_lines.pop(0)
        if content_lines:
            result[name] = "\n".join(content_lines)

    return result


def sections_to_markdown(case_id: str, sections: dict[str, str]) -> str:
    """Convert extracted sections to markdown format."""
    parts = [f"# 대법원 {case_id}", ""]

    if "판시사항" in sections:
        parts.append(f"Source: https://casenote.kr/대법원/{case_id}")
        parts.append("")

    if "주문" in sections:
        parts.append("## 주문")
        parts.append("")
        parts.append(sections["주문"])
        parts.append("")

    if "판결요지" in sections:
        parts.append("## 판결요지")
        parts.append("")
        parts.append(sections["판결요지"])
        parts.append("")

    if "이유" in sections:
        parts.append("## 이유")
        parts.append("")
        parts.append(sections["이유"])
        parts.append("")

    return "\n".join(parts)


def fetch_and_extract(case_id: str) -> str | None:
    """Fetch a case and return its markdown fulltext."""
    raw = fetch_case_text(case_id)
    if raw is None:
        return None
    sections = extract_sections(raw)
    if not sections:
        print(f"  Warning: no sections extracted for {case_id}", file=sys.stderr)
        return None
    return sections_to_markdown(case_id, sections)


def get_all_case_ids() -> list[str]:
    """Get all case IDs that have case.yaml and a court reference."""
    case_ids = []
    cases_dir = os.path.abspath(CASES_DIR)
    for name in sorted(os.listdir(cases_dir)):
        yaml_path = os.path.join(cases_dir, name, "case.yaml")
        if not os.path.isfile(yaml_path):
            continue
        with open(yaml_path) as f:
            data = yaml.safe_load(f)
        court = data.get("court")
        if court and court != "null":
            # Extract case ID from court string like "대법원 2005다71659"
            case_id = court.replace("대법원 ", "")
            case_ids.append((name, case_id))
    return case_ids


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/fetch-case.py <case-id>")
        print("       python3 scripts/fetch-case.py --all")
        print("       python3 scripts/fetch-case.py --verify")
        sys.exit(1)

    if sys.argv[1] == "--from-nix":
        outpath = get_nix_outpath()
        if not outpath:
            print("Failed to build .#case-html", file=sys.stderr)
            sys.exit(1)
        print(f"Using Nix outpath: {outpath}")
        cases = get_all_case_ids()
        for dir_name, case_id in cases:
            # Map case_id to nix filename: replace 다 with da
            nix_name = case_id.replace("다", "da") + ".html"
            html_path = os.path.join(outpath, nix_name)
            if not os.path.isfile(html_path):
                print(f"  {case_id}: not in nix outpath, skipping")
                continue
            print(f"Extracting: {case_id} ... ", end="", flush=True)
            raw = extract_from_html_file(html_path)
            if raw is None:
                print("FAILED")
                continue
            sections = extract_sections(raw)
            if not sections:
                print("NO SECTIONS")
                continue
            md = sections_to_markdown(case_id, sections)
            out_path = os.path.join(os.path.abspath(CASES_DIR), dir_name, "fulltext.md")
            with open(out_path, "w") as f:
                f.write(md)
            print("OK")

    elif sys.argv[1] == "--all":
        cases = get_all_case_ids()
        for dir_name, case_id in cases:
            print(f"Fetching: {case_id} ... ", end="", flush=True)
            md = fetch_and_extract(case_id)
            if md:
                out_path = os.path.join(os.path.abspath(CASES_DIR), dir_name, "fulltext.md")
                with open(out_path, "w") as f:
                    f.write(md)
                print("OK")
            else:
                print("FAILED")

    elif sys.argv[1] == "--verify":
        cases = get_all_case_ids()
        for dir_name, case_id in cases:
            existing_path = os.path.join(os.path.abspath(CASES_DIR), dir_name, "fulltext.md")
            if not os.path.isfile(existing_path):
                print(f"{case_id}: no existing fulltext.md")
                continue
            print(f"Verifying: {case_id} ... ", end="", flush=True)
            md = fetch_and_extract(case_id)
            if md is None:
                print("FETCH FAILED")
                continue
            with open(existing_path) as f:
                existing = f.read()
            if md.strip() == existing.strip():
                print("MATCH")
            else:
                print("DIFFERS")
                # Show first difference
                new_lines = md.strip().split("\n")
                old_lines = existing.strip().split("\n")
                for i, (n, o) in enumerate(zip(new_lines, old_lines)):
                    if n != o:
                        print(f"  Line {i+1}:")
                        print(f"  - stored:  {o[:80]}")
                        print(f"  + fetched: {n[:80]}")
                        break
                if len(new_lines) != len(old_lines):
                    print(f"  Line count: stored={len(old_lines)}, fetched={len(new_lines)}")
    else:
        case_id = sys.argv[1]
        md = fetch_and_extract(case_id)
        if md:
            print(md)
        else:
            print("Failed to fetch or extract.", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
