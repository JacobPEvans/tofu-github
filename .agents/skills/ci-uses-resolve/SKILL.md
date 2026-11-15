---
name: ci-uses-resolve
description: Fix a failing Uses Resolve check in the CI Gate of dryvist/tofu-github (unresolvable reusable workflow references or org pin policy findings).
triggers:
  - Uses Resolve
  - shared-gate / Uses Resolve
  - ci-gate-uses-resolve
---
# Uses Resolve

## What it checks

Every `uses:` in `.github/workflows/*.yml` resolves: a local
`./.github/workflows/<file>` exists, and an org workflow
(`JacobPEvans/.github`, `.github-ai`, `ai-workflows`) exists at the pinned
ref via the GitHub API. It also enforces org pin policy: `flake.nix` inputs
from org flakes need `?ref=v<major>`, `.envrc` must not `use flake` a remote
org flake, and `requirements.yml` org git sources must not pin a branch.
The `uses-resolve` job in `_ci-gate.yml` (check `shared-gate / Uses Resolve`),
via `.github/workflows/ci-gate.yml`, runs on every pull request.

## Reproduce locally

```bash
curl -fsSLo /tmp/ci-gate-uses-resolve.sh https://raw.githubusercontent.com/JacobPEvans/.github/v1/scripts/ci-gate-uses-resolve.sh
GH_TOKEN=$(gh auth token) bash /tmp/ci-gate-uses-resolve.sh
```

## Cheapest fix first

Fix the reference the error names: correct a mistyped path, or point the ref
at one that exists (confirm with `git ls-remote <repo-url> refs/tags/<ref>`)
and keep the `# vX.Y.Z` comment in sync. For pin-policy findings, pin the
flake input to `?ref=v<major>` (release tags pass too); a model edit applies
the correction.

## Never

- Delete, skip or weaken a test or assertion to make a check green.
- Delete the workflow or the `uses:` line to make a reference disappear; swap
  a pinned ref for a branch to dodge a missing tag.
- Add a Terraform `data "external"` or a script.
- Hard-code a value that belongs in a variable.

## Known causes

none recorded yet
