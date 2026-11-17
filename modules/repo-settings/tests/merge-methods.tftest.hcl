mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      repo_id = 1
    }
  }
}

run "rebase_merge_stays_on_by_default" {
  command = plan

  variables {
    name        = "ordinary-repo"
    description = "Ordinary repository"
    visibility  = "public"
  }

  assert {
    condition     = github_repository.this.allow_rebase_merge
    error_message = "Without allow_rebase_merge, the repository must keep rebase merging on."
  }
}

run "rebase_merge_off_when_the_org_turns_it_off" {
  command = plan

  variables {
    name               = "ordinary-repo"
    description        = "Ordinary repository"
    visibility         = "public"
    allow_rebase_merge = false
  }

  assert {
    condition = (
      !github_repository.this.allow_rebase_merge &&
      github_repository.this.allow_squash_merge &&
      github_repository.this.allow_merge_commit
    )
    error_message = "allow_rebase_merge = false must turn off rebase merging and keep squash and merge commits."
  }
}
