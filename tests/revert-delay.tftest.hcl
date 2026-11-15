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

run "adds_revert_delay_environment_to_every_gate_repository" {
  command = plan

  variables {
    github_owner              = "example-org"
    dryvist_org_extras        = false
    automation_bypass_app_ids = [1]
    codeql_import_enabled     = false
  }

  override_data {
    target = data.github_repositories.org
    values = {
      names = ["with-gate", "also-gated"]
    }
  }

  override_data {
    target = data.github_repositories.existing
    values = {
      names = []
    }
  }

  override_data {
    target = data.github_tree.ci_gate
    values = {
      entries = [{
        mode = "100644"
        path = ".github/workflows/ci.yml"
        sha  = "with-gate-workflow"
        size = 1
        type = "blob"
      }]
    }
  }

  override_data {
    target = data.github_repository_file.ci_gate
    values = {
      content = "name: CI\non: pull_request\njobs:\n  gate:\n    uses: example-org/.github/.github/workflows/_ci-gate.yml@v1\n"
    }
  }

  assert {
    condition = (
      github_repository_custom_property.ci_gate["with-gate"].property_value == toset(["true"]) &&
      github_repository_custom_property.ci_gate["also-gated"].property_value == toset(["true"])
    )
    error_message = "Both fixture repositories must call the shared gate."
  }

  assert {
    condition = (
      length(github_repository_environment.revert_delay) == 2 &&
      github_repository_environment.revert_delay["with-gate"].repository == "with-gate" &&
      github_repository_environment.revert_delay["with-gate"].environment == "revert-delay" &&
      github_repository_environment.revert_delay["with-gate"].wait_timer == 15 &&
      github_repository_environment.revert_delay["also-gated"].repository == "also-gated" &&
      github_repository_environment.revert_delay["also-gated"].environment == "revert-delay" &&
      github_repository_environment.revert_delay["also-gated"].wait_timer == 15
    )
    error_message = "Every gate repository must get the revert-delay environment with a fifteen-minute wait."
  }
}

run "adds_no_revert_delay_environment_without_a_gate_caller" {
  command = plan

  variables {
    github_owner              = "example-org"
    dryvist_org_extras        = false
    automation_bypass_app_ids = [1]
    codeql_import_enabled     = false
  }

  override_data {
    target = data.github_repositories.org
    values = {
      names = ["with-gate"]
    }
  }

  override_data {
    target = data.github_repositories.existing
    values = {
      names = []
    }
  }

  override_data {
    target = data.github_tree.ci_gate
    values = {
      entries = [{
        mode = "100644"
        path = ".github/workflows/ci.yml"
        sha  = "with-gate-workflow"
        size = 1
        type = "blob"
      }]
    }
  }

  override_data {
    target = data.github_repository_file.ci_gate
    values = {
      content = "name: CI\non: pull_request\njobs:\n  ci:\n    uses: example-org/.github/.github/workflows/_ci-gate.yml@v1\n"
    }
  }

  assert {
    condition     = length(github_repository_environment.revert_delay) == 0
    error_message = "A repository without a `gate` job must get no revert-delay environment."
  }
}
