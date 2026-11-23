# Per-repository text for the canonical CI-fix caller (.github/workflows/ci-fix.yml), set as the
# CI_FIX_REPO_CONTEXT, CI_FIX_CI_STRUCTURE and CI_FIX_EXTRA_TOOLS repository variables the caller reads.
# The AI_AGENT_CI_FIX_ENABLED and AI_AGENT_PR_REVIEW_ENABLED variables opt into their caller workflows.
# AI_AGENT_CI_FIX_DRY_RUN set to 'false' lets the CI-fix caller publish; the caller runs dry without it.
# Public repositories come from config/orgs/<owner>/ci-fix.yml; private repositories from the `ci_fix` key of
# their private repo override, so no private name is committed. A key that is unset or empty sets no variable.

locals {
  ci_fix_config = try(yamldecode(file("${local.org_config_dir}/ci-fix.yml")), {})
  ci_fix_repos = merge(
    try(local.ci_fix_config.repositories, {}),
    { for repo, cfg in local.private_repo_overrides : repo => cfg.ci_fix if try(cfg.ci_fix, null) != null },
  )
  ci_fix_variable_names = {
    repo_context               = "CI_FIX_REPO_CONTEXT"
    ci_structure               = "CI_FIX_CI_STRUCTURE"
    extra_tools                = "CI_FIX_EXTRA_TOOLS"
    ai_agent_ci_fix_enabled    = "AI_AGENT_CI_FIX_ENABLED"
    ai_agent_pr_review_enabled = "AI_AGENT_PR_REVIEW_ENABLED"
    ai_agent_ci_fix_dry_run    = "AI_AGENT_CI_FIX_DRY_RUN"
  }
  ci_fix_variables = merge([
    for repo, cfg in local.ci_fix_repos : {
      for key, name in local.ci_fix_variable_names : "${repo}/${name}" => {
        repository = repo
        name       = name
        value      = cfg[key]
      } if try(cfg[key], "") != ""
    }
  ]...)
}

resource "github_actions_variable" "ci_fix" {
  for_each = local.ci_fix_variables

  repository    = each.value.repository
  variable_name = each.value.name
  value         = each.value.value
}
