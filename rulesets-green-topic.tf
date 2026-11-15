# Org-wide protection for shared topic branches and the green branch.
#
# org-topic-branches covers refs/heads/topic/** on every repository and blocks
# non-fast-forward (force) pushes. It lists no bypass actors, so no actor —
# the automation apps included — can rewrite a shared topic branch's history.
# Day-to-day create and update policy for topic branches stays in the
# org-branch-write-restriction ruleset.
#
# org-green-branch covers refs/heads/green on every repository. The update rule
# closes green to every actor outside var.automation_bypass_app_ids, so only
# the automation App moves green forward; deletion and non-fast-forward (force)
# pushes are blocked for every other actor alongside it.
resource "github_organization_ruleset" "org_topic_branches" {
  name        = "org-topic-branches"
  target      = "branch"
  enforcement = "active"

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
  enforcement = "active"

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
    update           = true
  }

  dynamic "bypass_actors" {
    for_each = toset(var.automation_bypass_app_ids)
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "always"
    }
  }
}
