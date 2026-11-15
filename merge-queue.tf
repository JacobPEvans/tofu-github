# Native merge queue for hot repositories.
#
# `merge_tier: hot` in the selected per-org repos.yml opts a repository into
# GitHub's merge queue on its default branch. local.hot_repos is the single
# derivation of that set: later tier changes flow through local.managed_repos,
# so no second list is kept in sync. Archived repos are read-only and skipped.
# A repo's merge gate must report on merge_group before it goes hot, or queued
# PRs stall.
locals {
  merge_tier_declared = {
    for name, cfg in local.managed_repos : name => try(cfg.merge_tier, "legacy")
  }
  # The tiers with the rollback switch on: hot becomes standard, the rest stay.
  merge_tier_if_forced = {
    for name, tier in local.merge_tier_declared : name => tier == "hot" ? "standard" : tier
  }
  # The tier each repository really gets; merge-tier.tf and hot_repos read this.
  merge_tier_effective = (
    local.rulesets_defaults.merge_queue.force_standard
    ? local.merge_tier_if_forced
    : local.merge_tier_declared
  )
  hot_repos = [
    for name, cfg in local.managed_repos : name
    if local.merge_tier_effective[name] == "hot" && !try(cfg.archived, false)
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
  enforcement = local.rulesets_defaults.merge_queue.enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    merge_queue {
      merge_method                      = local.rulesets_defaults.merge_queue.merge_method
      grouping_strategy                 = local.rulesets_defaults.merge_queue.grouping_strategy
      max_entries_to_build              = local.rulesets_defaults.merge_queue.max_entries_to_build
      max_entries_to_merge              = local.rulesets_defaults.merge_queue.max_entries_to_merge
      min_entries_to_merge              = local.rulesets_defaults.merge_queue.min_entries_to_merge
      min_entries_to_merge_wait_minutes = local.rulesets_defaults.merge_queue.min_entries_to_merge_wait_minutes
      check_response_timeout_minutes    = local.rulesets_defaults.merge_queue.check_response_timeout_minutes
    }
  }

  lifecycle {
    # With per-entry lanes HEADGREEN lets a fast entry carry a failed entry in.
    precondition {
      condition     = local.rulesets_defaults.merge_queue.grouping_strategy == "ALLGREEN"
      error_message = "merge_queue.grouping_strategy in config/rulesets-defaults.yml must be ALLGREEN."
    }
  }

  # A renamed repo only answers to its new name after module.repo_settings
  # applies the rename.
  depends_on = [module.repo_settings]
}
