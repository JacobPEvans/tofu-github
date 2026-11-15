---
name: ci-tofu-ci
description: Fix a failing OpenTofu CI check (tofu fmt/validate, tflint) in the CI Gate of dryvist/tofu-github.
triggers:
  - OpenTofu CI
  - shared-gate / OpenTofu CI / OpenTofu
  - tflint
  - tofu fmt
  - tofu validate
---
# OpenTofu CI

## What it checks

`tofu fmt -check -recursive`; `tofu init -backend=false -input=false` and
`tofu validate -no-color` in the repository root; `tflint --config
.tflint.hcl --init && tflint --config .tflint.hcl -f compact` with this
repo's own `.tflint.hcl`. Job `OpenTofu` in `_tofu-ci.yml`, check name
`shared-gate / OpenTofu CI / OpenTofu`, called by
`.github/workflows/ci-gate.yml` (`shared-gate` job); runs on `**.tf`,
`**.tfvars`, `.terraform.lock.hcl`, `.tflint.hcl`, `tests/**`, `config/**`.

## Reproduce locally

Run from the repository root; `tofu` and `tflint` come from the Nix shell
(`nix develop`, loaded by direnv).

```bash
tofu fmt -check -recursive
tofu init -backend=false -input=false && tofu validate -no-color
tflint --config .tflint.hcl --init && tflint --config .tflint.hcl -f compact
```

## Cheapest fix first

Run `pre-commit run --all-files` — `.pre-commit-config.yaml` pins these hooks
to `tofu`, and `terraform_fmt` autofixes formatting (hooks need the Nix
shell). Edit by hand for what fmt cannot fix: tflint findings (naming,
undocumented variables/outputs, `#` comment style) and validate type errors.

## Never

- Delete, skip or weaken a test or assertion (including `tests/*.tftest.hcl`).
- Add `# noqa`, `# nosec`, `skip_ansible_lint`, `tflint-ignore` or a lint disable.
- Add a Terraform `data "external"` or a script.
- Hard-code a value that belongs in a variable (`variables.tf`, `config/*.yml`).

## Known causes

none recorded yet
