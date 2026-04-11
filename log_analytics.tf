# ============================================================
# log_analytics.tf
# ============================================================
# Log Analytics Workspace. This is a NEW addition from the
# previous version of this project.
#
# Why it's here:
#   Azure now auto-attaches a Log Analytics workspace to any
#   new Application Insights resource created in most regions.
#   If Terraform doesn't declare the workspace_id, the second
#   apply fails with:
#
#     Error: workspace_id can not be removed after set
#
#   By creating the workspace explicitly and passing its ID
#   into Application Insights, the whole pipeline becomes
#   idempotent — every apply sees the same state and makes
#   zero changes.
# ============================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_short_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(var.tags, {
    costcategory = "Monitoring"
  })
}
