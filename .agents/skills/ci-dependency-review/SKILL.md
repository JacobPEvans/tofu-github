---
name: ci-dependency-review
description: Fix a failing Dependency Review check in the CI Gate of dryvist/tofu-github (new dependency vulnerabilities at moderate severity or higher).
triggers:
  - Dependency Review
  - shared-gate / Dependency Review
  - dependency-review-action
---
# Dependency Review

## What it checks

Differential vulnerability scan of the PR's dependency changes via
`actions/dependency-review-action` with `fail-on-severity: moderate` — the
inline `dependency-review` job in `_ci-gate.yml`, check name
`shared-gate / Dependency Review`, called by `.github/workflows/ci-gate.yml`
(`shared-gate` job). It runs on every pull request of this public repo,
whatever paths changed, and fails when the diff adds a dependency version
with a known vulnerability of moderate severity or higher.

## Reproduce locally

No exact local reproduction exists: the action reads GitHub's dependency
graph. The failing job log names the flagged package, the advisory and the
patched version — read it via `gh run view --log-failed` or the PR checks
page.

## Cheapest fix first

Bump the flagged dependency to the patched version the advisory names. In
this repo dependency pins live in `.github/workflows/*.yml` (commit SHA plus
`# vX.Y.Z` comment) and in `.terraform.lock.hcl` (provider locks); update the
pin and its version comment together. No autofix exists — a model edit
applies the bump after reading the advisory.

## Never

- Delete, skip or weaken a test or assertion to make a check green.
- Silence the advisory (`ignore-vulns` or similar) or raise `fail-on-severity`.
- Downgrade a dependency to dodge the scan.
- Add a Terraform `data "external"`.
- Add a script.
- Hard-code a value that belongs in a variable.

## Known causes

none recorded yet
