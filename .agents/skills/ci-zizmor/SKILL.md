---
name: ci-zizmor
description: Fix a failing Workflow Security (zizmor) check in the CI Gate of dryvist/tofu-github.
triggers:
  - Workflow Security (zizmor)
  - shared-gate / Workflow Security (zizmor) / Workflow Security (zizmor)
  - zizmor
---
# Workflow Security (zizmor)

## What it checks

zizmor security audit of `.github/workflows`, with the org policy fetched
from `JacobPEvans/.github`, persona regular, minimum severity and confidence
medium — the `zizmor` job in `_zizmor.yml`, check name
`shared-gate / Workflow Security (zizmor) / Workflow Security (zizmor)`,
called by `.github/workflows/ci-gate.yml` (`shared-gate` job). Runs on every
pull request, whatever paths changed.

## Reproduce locally

```bash
curl -fsSLo /tmp/zizmor.yml https://raw.githubusercontent.com/JacobPEvans/.github/v1/zizmor.yml
uvx zizmor@1.26.1 --persona=regular --min-severity=medium --min-confidence=medium --config /tmp/zizmor.yml .github/workflows
```

Needs `uv` (uvx). Findings print with file, line and audit id.

## Cheapest fix first

No autofix exists. Apply the remediation the audit names, in the style the
other workflows here already use: pin an action to its full commit SHA with
a `# vX.Y.Z` comment, scope `permissions:` per job, or set
`persist-credentials: false` on checkouts; re-run the command to confirm.

## Never

- Delete, skip or weaken a test or assertion to make a check green.
- Add `# zizmor: ignore` or any audit-suppression comment or config override.
- Delete a workflow or job to clear a finding; swap a pinned SHA for a
  moving branch ref.
- Add a Terraform `data "external"`.
- Add a script.
- Hard-code a value that belongs in a variable.

## Known causes

none recorded yet
