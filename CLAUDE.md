# Deotonic

Curry-Howard correspondence for deontic logic, encoding Korean Civil Act (민법) as type-level defeasible rules.

## Packages

- `deontic-core/` — general deontic logic: GADTs, judgments, capacity, defeasible reasoning (Dung's argumentation)
- `deontic-kr-civil/` — Korean Civil Act encoding (§5 minors, §103-§107 juristic acts)
- `deontic-temporal/` — (incubated) temporal reasoning for time-dependent rules and 시행령 versioning

## Stack

- Haskell, GHC 9.6.7, Cabal multi-package, Nix flake
- Module namespace: `Deontic.*`
- Tests: HSpec

## Documentation Site

- Built with MkDocs Material, deployed to GitHub Pages
- English: `mkdocs.yml` → `docs/`
- Korean: `mkdocs-ko.yml` → `docs/ko/`
- Build: `mkdocs build && mkdocs build -f mkdocs-ko.yml -d site/ko`
- Nix: `nix build .#mkdocs-site` builds both languages

### Bilingual Sync Workflow

English is the source of truth. Korean mirrors are maintained via translation subagent:

1. Edit English templates in `scripts/templates/*.md`
2. Run translation subagent with directive `scripts/directives/translate-ko.md` on changed files
3. Output goes to `scripts/templates/*.ko.md`
4. Assemble both versions: `python3 scripts/assemble-cases.py` (EN) and `python3 scripts/assemble-cases.py --ko` (KO)

Case data files (`docs/civil-act/cases/*/`) are shared — Korean docs symlink to them.

### Case Verification Pipeline

Each case has a zero-context LLM subagent compare `framework-output.md` against `fulltext.md`, producing `match.yaml`. Directive: `scripts/directives/verify-match.md`.

## Conventions

- Commits: atomic, one logical change each. Push frequently.
- Nix flake for dev environment. Use `nix develop -c <command>` for CLI tools.
- Never `pip install` — all Python deps go through Nix.
- Artifacts: plans, logs, devlogs go in `artifacts/` directories.
