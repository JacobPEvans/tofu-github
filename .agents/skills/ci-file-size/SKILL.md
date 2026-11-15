---
name: ci-file-size
description: Fix a failing File Size check in the CI Gate of dryvist/tofu-github (org byte limits on .md, .nix and .tf files).
triggers:
  - File Size
  - shared-gate / File Size / Check
  - check-file-sizes
  - file-size
---
# File Size

## What it checks

Byte size of every `.md`, `.nix` and `.tf` file, against org defaults from
`JacobPEvans/.github` (`configs/file-size-defaults.yml`): warn at 6 KB, fail
above 12 KB; `CHANGELOG.md` is exempt. Check name on the PR:
`shared-gate / File Size / Check` — the `Check` job in `_file-size.yml`,
called by `.github/workflows/ci-gate.yml` (`shared-gate` job); runs when the
PR touches markdown, nix or terraform paths.

## Reproduce locally

```bash
curl -fsSLo /tmp/check-file-sizes.sh https://raw.githubusercontent.com/JacobPEvans/.github/v1/scripts/check-file-sizes.sh
curl -fsSLo /tmp/file-size-defaults.yml https://raw.githubusercontent.com/JacobPEvans/.github/v1/configs/file-size-defaults.yml
FILE_SIZE_DEFAULTS_CONFIG=/tmp/file-size-defaults.yml bash /tmp/check-file-sizes.sh
```

Needs `yq` on PATH. Offenders print as `::error file=...` lines with their size and the limit.

## Cheapest fix first

Split the oversized file along natural seams — prose into per-topic pages,
`.tf` resources into a sibling file or module (config-level split, no state
impact). No formatter covers this check; use a model edit for the tightening.

## Never

- Delete, skip or weaken a test or assertion to make a check green.
- Add the failing file to `.file-size.yml` `exempt`/`extended` to dodge the
  limit; that override exists for pre-reviewed exceptions, not fixes.
- Rename a file so its extension escapes the scan.
- Add a Terraform `data "external"`.
- Add a script that splits or generates files.
- Hard-code a value that belongs in a variable.

## Known causes

none recorded yet
