---
name: ci-markdown-lint
description: Fix a failing Markdown Lint check (markdownlint-cli2) in the CI Gate of dryvist/tofu-github.
triggers:
  - Markdown Lint
  - shared-gate / Markdown Lint / Lint
  - markdownlint
  - markdownlint-cli2
---
# Markdown Lint (markdownlint-cli2)

## What it checks

markdownlint-cli2 over the `.md` files this PR adds or modifies, with the org
config from `JacobPEvans/.github` (this repo ships no `.markdownlint*` file):
MD013 line length 160, strict, for prose, headings and code; every other rule
at markdownlint defaults. `CHANGELOG.md` is excluded. Check name on the PR:
`shared-gate / Markdown Lint / Lint` — the `Lint` job in `_markdown-lint.yml`,
called by `.github/workflows/ci-gate.yml` (`shared-gate` job); runs on
`**.md` and `.markdownlint*` path changes.

## Reproduce locally

```bash
git diff --name-only --diff-filter=ACMR HEAD^1 HEAD -- '*.md' ':!CHANGELOG.md'  # CI's list; locally: git diff --name-only <base>...HEAD -- '*.md'
curl -fsSLo .markdownlint-cli2.yaml https://raw.githubusercontent.com/JacobPEvans/.github/v1/.markdownlint-cli2.yaml
npx markdownlint-cli2 'README.md' 'docs/**/*.md'  # replace globs with the files above
rm .markdownlint-cli2.yaml  # org config stays out of the repo
```

## Cheapest fix first

Rewrap lines over 160 characters and fix mechanical violations by hand
(trailing spaces, missing fence languages, heading spacing). No autofix
exists: `.pre-commit-config.yaml` has no markdownlint hook, so a model edit
does the fix, keeping the org defaults intact.

## Never

- Delete, skip or weaken a test or assertion to make a check green.
- Add `<!-- markdownlint-disable -->` or any other lint disable.
- Add a `.markdownlint*` config that lowers the org defaults (line length 160).
- Add a Terraform `data "external"`.
- Add a script that rewrites or generates Markdown.
- Hard-code a value that belongs in a variable.

## Known causes

none recorded yet
