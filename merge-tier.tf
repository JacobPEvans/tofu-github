# Merge tier policy.
#
# Every repo carries the `merge_tier` custom property as the single switch
# rulesets and workflows read instead of per-repo queue logic. It is required
# with the default "legacy": today's merge behaviour, no tier-specific gating.
# "standard" merges without a queue; "hot" opts a repository into the native
# merge queue.
resource "github_organization_custom_properties" "merge_tier" {
  property_name      = "merge_tier"
  value_type         = "single_select"
  required           = true
  default_value      = "legacy"
  allowed_values     = ["legacy", "standard", "hot"]
  values_editable_by = "org_actors"
}

# Set the tier on every unarchived managed repo. A repos.yml entry selects its
# value with `merge_tier:`; every other repo inherits the "legacy" default.
# merge_queue.force_standard in config/rulesets-defaults.yml turns hot into
# standard for every repo (local.merge_tier_effective in merge-queue.tf).
# Archived repos are read-only and skipped.
resource "github_repository_custom_property" "merge_tier" {
  for_each = {
    for name, cfg in local.managed_repos : name => cfg if !try(cfg.archived, false)
  }

  repository     = each.key
  property_name  = github_organization_custom_properties.merge_tier.property_name
  property_type  = "single_select"
  property_value = [local.merge_tier_effective[each.key]]
}
