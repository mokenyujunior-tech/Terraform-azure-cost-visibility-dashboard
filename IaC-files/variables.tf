variable "subscription_id" {
  description = "Azure subscription ID. Passed via TF_VAR_subscription_id from GitHub Secrets."
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "canadacentral"
}

variable "resource_group_name" {
  description = "Name of the main resource group that holds the cost visibility dashboard."
  type        = string
  default     = "rg-cost-visibility"
}

variable "project_short_name" {
  description = "Short identifier used in resource names to keep them unique and readable."
  type        = string
  default     = "cvd"
}

variable "owner_email" {
  description = "Email that receives budget alerts, anomaly alerts and weekly cost reports."
  type        = string
  sensitive   = true
}

variable "monthly_budget_amount" {
  description = "Monthly spending limit in CAD that drives the Azure Budget resource."
  type        = number
  default     = 200
}

variable "vm_admin_username" {
  description = "Admin username for the cost-monitoring lab VM."
  type        = string
  default     = "mokadmin"
}

variable "ssh_allowed_source_ip" {
  description = "Public IP allowed to SSH into the lab VM. Change this if your ISP rotates your IP."
  type        = string
  default     = "198.96.84.204"
}

variable "vm_size" {
  description = "Azure VM SKU. B2ts_v2 is the cheapest non-retiring burstable available in Canada Central."
  type        = string
  default     = "Standard_B2ts_v2"
}

variable "weekly_report_cron" {
  description = "NCRONTAB expression that triggers the Function App. Default: every Monday at 08:00 UTC."
  type        = string
  default     = "0 0 8 * * 1"
}

variable "tags" {
  description = "Base tags applied to every resource. costcategory is overridden per-resource."
  type        = map(string)
  default = {
    project     = "cost-visibility"
    environment = "dev"
    deployment  = "terraform"
    owner       = "mokcloud"
    department  = "IT"
  }
}
