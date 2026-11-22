# Restrict updates of selected default branches to the listed pull-request bypass actors.
# merge-restriction.yml may set `enforcement` (disabled, evaluate or active); the default is active.
resource "github_organization_ruleset" "org_default_branch_merge_restriction" {
  count       = length(local.merge_restriction_config.repos) == 0 ? 0 : 1
  name        = "org-default-branch-merge-restriction"
  target      = "branch"
  enforcement = try(local.merge_restriction_config.enforcement, "active")

  lifecycle {
    precondition {
      condition     = length(local.merge_restriction_config.repos) == 0 || length(var.merge_bypass_app_ids) > 0
      error_message = "merge_bypass_app_ids must list at least one GitHub App ID when merge-restriction.yml lists repositories."
    }
  }

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/main", "refs/heads/develop"]
      exclude = []
    }
    repository_name {
      include = local.merge_restriction_config.repos
      exclude = []
    }
  }

  rules {
    update = true
  }

  dynamic "bypass_actors" {
    for_each = toset(var.merge_bypass_app_ids)
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "pull_request"
    }
  }

  bypass_actors {
    actor_id    = null
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }
}
