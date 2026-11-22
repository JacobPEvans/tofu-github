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
