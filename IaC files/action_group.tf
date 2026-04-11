# ============================================================
# action_group.tf
# ============================================================
# Monitor Action Group that fires the Logic App when a budget
# threshold or anomaly alert triggers.
#
# Lessons baked in:
#   - location MUST be "global" for action groups
#   - use_common_alert_schema = true so the Logic App
#     receives a predictable payload with essentials
#   - Explicit depends_on on the Logic App deployment so
#     local.logic_app_callback_url is populated first
# ============================================================

resource "azurerm_monitor_action_group" "cost_alerts" {
  name                = "ag-cost-alerts-${var.project_short_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "costalerts"

  # Action groups are global resources.
  location = "global"

  logic_app_receiver {
    name                    = "cost-alert-emailer"
    resource_id             = local.logic_app_id
    callback_url            = local.logic_app_callback_url
    use_common_alert_schema = true
  }

  tags = merge(var.tags, {
    costcategory = "Automation"
  })

  depends_on = [
    azurerm_resource_group_template_deployment.logic_app,
  ]
}
