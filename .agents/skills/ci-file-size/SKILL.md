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

Byte size of every `.md`, `.nix` and `.tf` file, against org defaults from the
shared workflow repository named in the `uses:` line of `.github/workflows/ci-gate.yml`
(`configs/file-size-defaults.yml`): warn at 6 KB, fail
above 12 KB; `CHANGELOG.md` is exempt. Check name on the PR:
`shared-gate / File Size / Check` — the `Check` job in `_file-size.yml`,
called by `.github/workflows/ci-gate.yml` (`shared-gate` job); runs when the
PR touches markdown, nix or terraform paths.

## Reproduce locally

```bash
# owner/repo/ref of the shared workflows, read from this repo's own caller
SRC=$(sed -nE 's#.*uses: ([^/]+/[^/]+)/\.github/workflows/_ci-gate\.yml@([^ ]+).*#\1/\2#p' .github/workflows/ci-gate.yml)
curl -fsSLo /tmp/check-file-sizes.sh "https://raw.githubusercontent.com/$SRC/scripts/check-file-sizes.sh"
curl -fsSLo /tmp/file-size-defaults.yml "https://raw.githubusercontent.com/$SRC/configs/file-size-defaults.yml"
FILE_SIZE_DEFAULTS_CONFIG=/tmp/file-size-defaults.yml bash /tmp/check-file-sizes.sh
```

Needs `yq` on PATH. Offenders print as `::error file=...` lines with their size and the limit.

## Cheapest fix first

A size failure is fixed by moving, not by removing. The total content after the change equals the content before;
only its place changes. Split the oversized file along natural seams: prose into per-topic pages, `.tf` blocks into
a sibling file or module (a config-level split, no state impact). Then run every check the moved files feed:
`tofu fmt -check -recursive`, `tofu validate`, `tflint`, and `tofu test` when tests exist.

## Worked example

`variables.tf` and `README.md` are over the 12 KB limit.

- Wrong: deleting variable blocks and README text. One deleted variable was still referenced,
  so `tofu validate` fails with "Reference to undeclared input variable"; an edited file that skipped the formatter fails
  `tofu fmt -check`.
- Right: move whole `variable` blocks, unchanged, into a new sibling file grouped by topic, for example
  `variables-rulesets.tf`, and move whole README sections into `docs/<topic>.md` with a one-line link left in
  their place. Run `tofu fmt -recursive`, then `tofu validate` and `tflint`. Every reference still resolves and no
  declaration is left unused.

## Never

- Delete, skip or weaken a test or assertion to make a check green.
- Add the failing file to `.file-size.yml` `exempt`/`extended` to dodge the
  limit; that override exists for pre-reviewed exceptions, not fixes.
- Rename a file so its extension escapes the scan.
- Add a Terraform `data "external"`.
- Add a script that splits or generates files.
- Hard-code a value that belongs in a variable.

## Known causes

- Variables or text deleted instead of moved: `tofu validate` or `tofu fmt -check` fails after the fix.
- A correct split that leaves a `data` source unused: `tflint` fails after the fix.
