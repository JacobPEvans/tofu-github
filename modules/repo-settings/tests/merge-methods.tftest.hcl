mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      repo_id = 1
    }
  }
}

run "rebase_merge_off_by_default" {
  command = plan

  variables {
    name        = "ordinary-repo"
    description = "Ordinary repository"
    visibility  = "public"
  }

  assert {
    condition = (
      !github_repository.this.allow_rebase_merge &&
      github_repository.this.allow_squash_merge &&
      github_repository.this.allow_merge_commit
    )
    error_message = "Without allow_rebase_merge, rebase merging must be off while squash and merge commits stay on."
  }
}

run "rebase_merge_on_when_the_org_turns_it_on" {
  command = plan

  variables {
    name               = "ordinary-repo"
    description        = "Ordinary repository"
    visibility         = "public"
    allow_rebase_merge = true
  }

  assert {
    condition     = github_repository.this.allow_rebase_merge
    error_message = "allow_rebase_merge = true must turn rebase merging on."
  }
}
