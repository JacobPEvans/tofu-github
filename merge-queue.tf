# Native merge queue for hot repositories.
#
# `merge_tier: hot` in the selected per-org repos.yml opts a repository into
# GitHub's merge queue on its default branch. local.hot_repos is the single
# derivation of that set: later tier changes flow through local.managed_repos,
# so no second list is kept in sync. Archived repos are read-only and skipped.
# A repo's merge gate must report on merge_group before it goes hot, or queued
# PRs stall.
locals {
  hot_repos = [
    for name, cfg in local.managed_repos : name
    if try(cfg.merge_tier, "legacy") == "hot" && !try(cfg.archived, false)
  ]
}

# One queue ruleset per hot repo, bound to ~DEFAULT_BRANCH so it follows the
# live default branch (main on trunk repos, develop on git-flow repos). No
# bypass actors: every merge goes through the queue.
resource "github_repository_ruleset" "merge_queue" {
  for_each = toset(local.hot_repos)

  repository  = each.key
  name        = "merge-queue"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    merge_queue {
      merge_method                      = "SQUASH"
      grouping_strategy                 = "ALLGREEN"
      max_entries_to_build              = 5
      max_entries_to_merge              = 5
      min_entries_to_merge              = 1
      min_entries_to_merge_wait_minutes = 0
      check_response_timeout_minutes    = 30
    }
  }

  # A renamed repo only answers to its new name after module.repo_settings
  # applies the rename.
  depends_on = [module.repo_settings]
}
