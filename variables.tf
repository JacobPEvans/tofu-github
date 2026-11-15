# Workspace and opt-in inputs. The per-ruleset enforcement switches live in
# enforcement.tf.

variable "automation_bypass_app_ids" {
  description = <<-EOT
    Required workspace list with no default: GitHub App IDs allowed to create/update branches covered by the restriction. Non-empty avoids locking out all automation; include every branch-writer (Actions, dependency-update, release, and org apps).
  EOT
  type        = list(number)

  validation {
    condition     = length(var.automation_bypass_app_ids) > 0
    error_message = "automation_bypass_app_ids must list at least one GitHub App ID."
  }
}

# Workspace selectors.
variable "github_owner" {
  description = "GitHub org login to manage: 1-39 letters, digits, or hyphens."
  type        = string
  default     = "dryvist"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,39}$", var.github_owner))
    error_message = "github_owner must contain 1-39 letters, numbers, or hyphens."
  }
}

variable "dryvist_org_extras" {
  description = "Enable organization-specific opt-in policies."
  type        = bool
  default     = true
}

# Hermes PR-review webhook sends pull_request events; created only when both
# variables are set.
variable "hermes_webhook_url" {
  description = "Hermes PR-review intake URL; empty skips the webhook."
  type        = string
  sensitive   = true
  default     = ""
}

variable "hermes_webhook_secret" {
  description = "GitHub HMAC signing secret (X-Hub-Signature-256); empty skips the webhook."
  type        = string
  sensitive   = true
  default     = ""
}

# Event queue intake for check_run and pull_request events. Off until the intake
# records exist in Vault, so the plan never reads absent paths.
variable "event_queue_webhook_enabled" {
  description = "Create the event queue org webhook from the intake records in Vault."
  type        = bool
  default     = false
}

variable "event_forwarder_enabled" {
  description = "Enable the org-wide event-forwarder required workflow."
  type        = bool
  default     = false
}

variable "event_forwarder_enforcement" {
  description = "Event-forwarder required-workflow enforcement mode."
  type        = string
  default     = "evaluate"
  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.event_forwarder_enforcement)
    error_message = "Use disabled, evaluate or active."
  }
}
