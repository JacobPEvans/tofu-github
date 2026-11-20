# Owners the PR Reconcile sweep covers, set as the PR_RECONCILE_OWNERS variable
# on the repository that runs the sweep. Only an owner with
# config/orgs/<owner>/pr-reconcile.yml manages it; like ai-untrusted.yml, the
# file is the opt-in, so dryvist_org_extras does not gate it.
resource "github_actions_variable" "pr_reconcile_owners" {
  count = local.pr_reconcile_config == null ? 0 : 1

  repository    = try(local.pr_reconcile_config.sweep_repository, "")
  variable_name = "PR_RECONCILE_OWNERS"
  value         = join(",", try(local.pr_reconcile_config.owners, []))

  lifecycle {
    precondition {
      condition     = try(local.pr_reconcile_config.sweep_repository, "") != "" && length(try(local.pr_reconcile_config.owners, [])) > 0
      error_message = "config/orgs/<owner>/pr-reconcile.yml needs sweep_repository and a non-empty owners list."
    }
  }
}

resource "github_actions_variable" "pr_reconcile_claude_bot_id" {
  count = local.pr_reconcile_config == null ? 0 : 1

  repository    = try(local.pr_reconcile_config.sweep_repository, "")
  variable_name = "GH_APP_CLAUDE_BOT_ID"
  value         = try(local.pr_reconcile_config.claude_bot_app_id, "")

  lifecycle {
    precondition {
      condition     = try(local.pr_reconcile_config.sweep_repository, "") != "" && try(local.pr_reconcile_config.claude_bot_app_id, "") != ""
      error_message = "config/orgs/<owner>/pr-reconcile.yml needs sweep_repository and claude_bot_app_id."
    }
  }
}

# Optional: the caller workflow file the sweep starts in a repository whose
# pull request fails a code check. Unset, the sweep starts no CI fix.
resource "github_actions_variable" "pr_reconcile_ci_fix_workflow" {
  count = try(local.pr_reconcile_config.ci_fix_workflow, null) == null ? 0 : 1

  repository    = try(local.pr_reconcile_config.sweep_repository, "")
  variable_name = "PR_RECONCILE_CI_FIX_WORKFLOW"
  value         = try(local.pr_reconcile_config.ci_fix_workflow, "")

  lifecycle {
    precondition {
      condition     = try(local.pr_reconcile_config.sweep_repository, "") != "" && can(regex("^[A-Za-z0-9._-]+\\.ya?ml$", try(local.pr_reconcile_config.ci_fix_workflow, "")))
      error_message = "config/orgs/<owner>/pr-reconcile.yml ci_fix_workflow needs sweep_repository and a workflow file name ending in .yml or .yaml."
    }
  }
}

# Optional: merge: true sets PR_RECONCILE_MERGE, so the sweep merges a bot pull
# request that is green at its exact head. Unset or false, the sweep never merges.
resource "github_actions_variable" "pr_reconcile_merge" {
  count = try(local.pr_reconcile_config.merge, false) == true ? 1 : 0

  repository    = try(local.pr_reconcile_config.sweep_repository, "")
  variable_name = "PR_RECONCILE_MERGE"
  value         = "true"

  lifecycle {
    precondition {
      condition     = try(local.pr_reconcile_config.sweep_repository, "") != ""
      error_message = "config/orgs/<owner>/pr-reconcile.yml merge needs sweep_repository."
    }
  }
}
