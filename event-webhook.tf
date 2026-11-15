# Event-forwarder opt-in and enforcement. The ruleset itself lives in
# rulesets-required-workflows.tf.
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
