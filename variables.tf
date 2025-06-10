variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "alarms_config_path" {
  description = "Path to the alarms configuration JSON file"
  type        = string
}

variable "slack_webhook_urls" {
  description = "Map of Slack webhook URLs for different channels"
  type        = map(string)
  sensitive   = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 