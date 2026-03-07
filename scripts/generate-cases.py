#!/usr/bin/env python3
"""Generate framework-output.md for each case directory.

Reads eval expression from case.yaml, runs it through ghci.
"""
import os
import subprocess
import sys
import yaml

CASES_DIR = os.path.join(os.path.dirname(__file__), "..", "docs", "civil-act", "cases")
PROJECT_ROOT = os.path.join(os.path.dirname(__file__), "..")


def extract_eval(case_yaml: dict) -> str | None:
    """Extract the eval expression from case.yaml."""
    return case_yaml.get("eval")


def run_ghci(eval_expr: str) -> str | None:
    """Run a Haskell expression through ghci and capture output."""
    # Strip leading whitespace uniformly (YAML block scalar indentation)
    lines = eval_expr.strip().split("\n")

    result = subprocess.run(
        [
            "nix", "develop", "-c",
            "cabal", "exec", "ghci", "--",
            "-v0", "-ignore-dot-ghci",
            "-package", "deontic-kr-civil",
            "-XOverloadedStrings",
            "scripts/GenCaseOutput.hs",
            "-e", eval_expr.strip(),
        ],
        capture_output=True,
        text=True,
        cwd=PROJECT_ROOT,
        timeout=60,
    )
    if result.returncode != 0:
        print(f"  stderr: {result.stderr[:200]}", file=sys.stderr)
        return None
    return result.stdout


def main():
    cases_dir = os.path.abspath(CASES_DIR)
    for case_name in sorted(os.listdir(cases_dir)):
        case_dir = os.path.join(cases_dir, case_name)
        yaml_path = os.path.join(case_dir, "case.yaml")
        if not os.path.isfile(yaml_path):
            continue

        with open(yaml_path, "r") as f:
            case_data = yaml.safe_load(f)

        eval_expr = extract_eval(case_data)
        if not eval_expr:
            print(f"Skipping: {case_name} (no eval)")
            continue

        print(f"Generating: {case_name} ... ", end="", flush=True)

        output = run_ghci(eval_expr)
        output_path = os.path.join(case_dir, "framework-output.md")

        if output is not None:
            # Filter out nix/cabal warnings
            clean_lines = [
                line for line in output.split("\n")
                if not line.startswith("warning: Git tree")
            ]
            with open(output_path, "w") as f:
                f.write("\n".join(clean_lines))
            print("OK")
        else:
            with open(output_path, "w") as f:
                f.write("(생성 실패)\n")
            print("FAILED")

    print("Done.")


if __name__ == "__main__":
    main()
