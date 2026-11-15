# Org-wide protection for shared topic branches and the green branch.
#
# org-topic-branches covers refs/heads/topic/** on every repository and blocks
# non-fast-forward (force) pushes.
#
# org-green-branch covers refs/heads/green on every repository and blocks
# non-fast-forward (force) pushes and deletion, so green only moves forward.
#
# Neither ruleset lists a bypass actor, so no actor, the automation apps
# included, can rewrite or delete these branches. Who may create and update
# them stays in the org-branch-write-restriction ruleset.
resource "github_organization_ruleset" "org_topic_branches" {
  name        = "org-topic-branches"
  target      = "branch"
  enforcement = var.org_topic_branches_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/topic/**"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    non_fast_forward = true
  }
}

resource "github_organization_ruleset" "org_green_branch" {
  name        = "org-green-branch"
  target      = "branch"
  enforcement = var.org_green_branch_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/green"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    non_fast_forward = true
    deletion         = true
  }
}
