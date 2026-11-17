# Adopt the live org Actions settings, so an org's first plan diffs against
# them instead of overwriting them. A no-op once they are in state.
import {
  for_each = var.codeql_import_enabled ? toset([local.org]) : toset([])
  to       = github_actions_organization_permissions.org
  id       = each.value
}

import {
  for_each = var.codeql_import_enabled ? toset([local.org]) : toset([])
  to       = github_actions_organization_workflow_permissions.org
  id       = each.value
}

resource "github_actions_organization_permissions" "org" {
  enabled_repositories = local.actions_defaults.enabled_repositories
  allowed_actions      = local.actions_defaults.allowed_actions
  sha_pinning_required = local.actions_defaults.sha_pinning_required
}

resource "github_actions_organization_workflow_permissions" "org" {
  organization_slug                = local.org
  default_workflow_permissions     = local.actions_defaults.default_workflow_permissions
  can_approve_pull_request_reviews = local.actions_defaults.can_approve_pull_request_reviews
}
