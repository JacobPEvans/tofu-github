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
      names = ["with-gate", "also-gated"]
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

# A targeted plan includes whatever its targets depend on. None of the six
# per-repository resources below may depend on module.repo_settings, so the
# module has no instance in this plan.
run "targeted_plan_of_per_repository_extras_names_no_repo_settings_address" {
  command = plan

  variables {
    github_owner              = "tofu-test-fixture"
    automation_bypass_app_ids = [1]
    codeql_import_enabled     = false
  }

  plan_options {
    target = [
      github_repository_custom_property.merge_tier,
      github_repository_custom_property.ci_gate,
      github_repository_custom_property.family,
      github_repository_custom_property.gitflow,
      github_repository_ruleset.merge_queue,
      github_repository_environment.revert_delay,
    ]
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
      names = ["sample"]
    }
  }

  assert {
    condition = (
      github_repository_custom_property.merge_tier["sample"].property_value == toset(["hot"]) &&
      contains(keys(github_repository_custom_property.gitflow), "sample") &&
      contains(keys(github_repository_custom_property.ci_gate), "sample") &&
      contains(keys(github_repository_ruleset.merge_queue), "sample")
    )
    error_message = "The targeted plan must cover the properties and the queue ruleset of the fixture repository."
  }

  assert {
    condition     = length(module.repo_settings) == 0
    error_message = "A targeted plan of the per-repository properties, queue rulesets and environments must not include module.repo_settings."
  }
}

# A ruleset whose conditions name the `gitflow` custom property cannot apply
# before that property exists: on a fresh org GitHub rejects it with 422
# "Invalid property 'gitflow' with source 'custom'". Each run below targets
# one conditioned ruleset alone; a targeted plan includes whatever its targets
# depend on, so the property resource being planned at all is the proof of
# `depends_on = [github_organization_custom_properties.gitflow]` — and the
# assertion on the property is what fails if that dependency is absent.
run "org_gitflow_main_plans_the_gitflow_custom_property" {
  command = plan

  variables {
    github_owner              = "tofu-test-fixture"
    automation_bypass_app_ids = [1]
    codeql_import_enabled     = false
  }

  plan_options {
    target = [restapi_object.org_gitflow_main]
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
      github_organization_custom_properties.gitflow.property_name == "gitflow"
    )
    error_message = "org-gitflow-main conditions on the `gitflow` property, so its plan must include github_organization_custom_properties.gitflow."
  }
}

run "org_gitflow_develop_plans_the_gitflow_custom_property" {
  command = plan

  variables {
    github_owner              = "tofu-test-fixture"
    automation_bypass_app_ids = [1]
    codeql_import_enabled     = false
  }

  plan_options {
    target = [restapi_object.org_gitflow_develop]
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
      github_organization_custom_properties.gitflow.property_name == "gitflow"
    )
    error_message = "org-gitflow-develop conditions on the `gitflow` property, so its plan must include github_organization_custom_properties.gitflow."
  }
}

run "org_branch_protection_plans_the_gitflow_custom_property" {
  command = plan

  variables {
    github_owner              = "tofu-test-fixture"
    automation_bypass_app_ids = [1]
    codeql_import_enabled     = false
  }

  plan_options {
    target = [restapi_object.org_branch_protection]
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
      github_organization_custom_properties.gitflow.property_name == "gitflow"
    )
    error_message = "org-branch-protection excludes git-flow repos through the `gitflow` property, so its plan must include github_organization_custom_properties.gitflow."
  }
}

run "org_review_gate_plans_the_gitflow_custom_property" {
  command = plan

  variables {
    github_owner              = "tofu-test-fixture"
    automation_bypass_app_ids = [1]
    codeql_import_enabled     = false
  }

  plan_options {
    target = [restapi_object.org_review_gate]
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
      github_organization_custom_properties.gitflow.property_name == "gitflow"
    )
    error_message = "org-review-gate excludes git-flow repos through the `gitflow` property, so its plan must include github_organization_custom_properties.gitflow."
  }
}

run "org_release_freeze_plans_the_gitflow_custom_property" {
  command = plan

  variables {
    github_owner              = "tofu-test-fixture"
    automation_bypass_app_ids = [1]
    codeql_import_enabled     = false
  }

  plan_options {
    target = [github_organization_ruleset.org_release_freeze]
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
      length(github_organization_ruleset.org_release_freeze) == 1 &&
      github_organization_custom_properties.gitflow.property_name == "gitflow"
    )
    error_message = "org-release-freeze conditions on the `gitflow` property, so its plan must include github_organization_custom_properties.gitflow."
  }
}
