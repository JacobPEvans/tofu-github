# Merge-queue ruleset coverage (G02): one active queue ruleset per hot repo.
mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      repo_id = 1
    }
  }

  mock_data "github_repository" {
    defaults = {
      default_branch = "main"
      full_name      = "example-org/.github"
      repo_id        = 1
      topics         = []
      visibility     = "public"
    }
  }

  mock_data "github_repositories" {
    defaults = {
      names = ["sample"]
    }
  }

  mock_data "github_actions_organization_variables" {
    defaults = {
      variables = []
    }
  }

  mock_data "github_repository_file" {
    defaults = {
      content = "[]"
    }
  }

  mock_data "github_repository_branches" {
    defaults = {
      branches = [{ name = "main", protected = false }]
    }
  }

  mock_data "github_branch" {
    defaults = {
      sha = "test-commit"
    }
  }

  mock_data "github_tree" {
    defaults = {
      entries = []
    }
  }

  mock_data "github_app" {
    defaults = {
      id = "1"
    }
  }
}

mock_provider "vault" {
  mock_data "vault_kv_secret_v2" {
    defaults = {
      data_json = <<-JSON
        {
          "private_repo_overrides": {
            "example-a": {
              "description": "",
              "topics": [],
              "visibility": "private",
              "main_from_renovate_preset": true,
              "merge_gate": { "gate": { "context": "gate / Merge Gate" } }
            },
            "example-b": {
              "description": "",
              "topics": [],
              "visibility": "private",
              "main_from_renovate_preset": true,
              "merge_gate": { "gate": { "context": "gate / Merge Gate" } }
            }
          }
        }
        JSON
    }
  }
}

mock_provider "restapi" {}

mock_provider "restapi" {
  alias = "no_body"
}

run "merge_queue_ruleset_per_hot_repository" {
  command = plan

  variables {
    github_owner              = "tofu-test-fixture"
    automation_bypass_app_ids = [1]
    codeql_import_enabled     = false
  }

  override_data {
    target = data.github_repositories.org
    values = {
      names = []
    }
  }

  override_data {
    target = data.github_repositories.existing
    values = {
      names = []
    }
  }

  assert {
    condition = (
      toset(local.hot_repos) == toset(["sample"]) &&
      toset(keys(github_repository_ruleset.merge_queue)) == toset(local.hot_repos)
    )
    error_message = "Exactly one merge-queue ruleset must be planned per hot repository; only the fixture's sample repo is hot."
  }

  assert {
    condition = (
      !contains(keys(github_repository_ruleset.merge_queue), ".github") &&
      !contains(keys(github_repository_ruleset.merge_queue), ".github-private")
    )
    error_message = "Repositories on the legacy tier must not get a merge-queue ruleset."
  }

  assert {
    condition = (
      github_repository_ruleset.merge_queue["sample"].repository == "sample" &&
      github_repository_ruleset.merge_queue["sample"].name == "merge-queue" &&
      github_repository_ruleset.merge_queue["sample"].target == "branch" &&
      github_repository_ruleset.merge_queue["sample"].enforcement == "active" &&
      length(github_repository_ruleset.merge_queue["sample"].bypass_actors) == 0
    )
    error_message = "The merge-queue ruleset must be active on its repository's branches with no bypass actors."
  }

  assert {
    condition = (
      toset(github_repository_ruleset.merge_queue["sample"].conditions[0].ref_name[0].include) == toset(["~DEFAULT_BRANCH"]) &&
      length(github_repository_ruleset.merge_queue["sample"].conditions[0].ref_name[0].exclude) == 0
    )
    error_message = "The merge queue must target ~DEFAULT_BRANCH with no excluded refs."
  }

  assert {
    condition = (
      github_repository_ruleset.merge_queue["sample"].rules[0].merge_queue[0].merge_method == "SQUASH" &&
      github_repository_ruleset.merge_queue["sample"].rules[0].merge_queue[0].grouping_strategy == "ALLGREEN" &&
      github_repository_ruleset.merge_queue["sample"].rules[0].merge_queue[0].max_entries_to_build == 5 &&
      github_repository_ruleset.merge_queue["sample"].rules[0].merge_queue[0].max_entries_to_merge == 5 &&
      github_repository_ruleset.merge_queue["sample"].rules[0].merge_queue[0].min_entries_to_merge == 1 &&
      github_repository_ruleset.merge_queue["sample"].rules[0].merge_queue[0].min_entries_to_merge_wait_minutes == 0 &&
      github_repository_ruleset.merge_queue["sample"].rules[0].merge_queue[0].check_response_timeout_minutes == 30
    )
    error_message = "The merge queue rule must carry the F04 values exactly."
  }
}
