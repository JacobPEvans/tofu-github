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

run "green_and_topic_rulesets_protect_shared_branches" {
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
      github_organization_ruleset.org_topic_branches.name == "org-topic-branches" &&
      github_organization_ruleset.org_topic_branches.target == "branch" &&
      github_organization_ruleset.org_topic_branches.enforcement == "active" &&
      tolist(github_organization_ruleset.org_topic_branches.conditions[0].ref_name[0].include) == tolist(["refs/heads/topic/**"]) &&
      tolist(github_organization_ruleset.org_topic_branches.conditions[0].repository_name[0].include) == tolist(["~ALL"]) &&
      github_organization_ruleset.org_topic_branches.rules[0].non_fast_forward == true &&
      length(github_organization_ruleset.org_topic_branches.bypass_actors) == 0
    )
    error_message = "The topic-branch ruleset must cover refs/heads/topic/** on every repository, block force pushes, and list no bypass actors."
  }

  assert {
    condition = (
      github_organization_ruleset.org_green_branch.name == "org-green-branch" &&
      github_organization_ruleset.org_green_branch.target == "branch" &&
      github_organization_ruleset.org_green_branch.enforcement == "active" &&
      tolist(github_organization_ruleset.org_green_branch.conditions[0].ref_name[0].include) == tolist(["refs/heads/green"]) &&
      tolist(github_organization_ruleset.org_green_branch.conditions[0].repository_name[0].include) == tolist(["~ALL"]) &&
      github_organization_ruleset.org_green_branch.rules[0].non_fast_forward == true &&
      github_organization_ruleset.org_green_branch.rules[0].deletion == true &&
      length(github_organization_ruleset.org_green_branch.bypass_actors) == 0
    )
    error_message = "The green-branch ruleset must cover refs/heads/green on every repository, block force pushes and deletion, and list no bypass actors."
  }
}
