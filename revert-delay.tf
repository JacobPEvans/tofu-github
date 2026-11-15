# The post-merge revert path.
#
# Every gate repository gets a "revert-delay" deployment environment. A
# workflow job targeting it waits fifteen minutes after it is triggered
# before it starts, and the wait holds no runner. No reviewers and no
# deployment branch policy gate the environment; the timer alone delays
# the run.
#
# Archived repos are read-only and skipped.
resource "github_repository_environment" "revert_delay" {
  for_each = toset([
    for name in local.ci_gate_repos : name if !try(local.managed_repos[name].archived, false)
  ])

  repository  = each.value
  environment = "revert-delay"
  wait_timer  = 15

  depends_on = [module.repo_settings]
}
