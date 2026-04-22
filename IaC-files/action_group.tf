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
