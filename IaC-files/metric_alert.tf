resource "azurerm_monitor_action_group" "metric_alerts" {
  name                = "ag-metric-alerts-cvd-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "metricalrt"

  email_receiver {
    name                    = "owner-email"
    email_address           = var.owner_email
    use_common_alert_schema = true
  }

  tags = merge(var.tags, {
    costcategory = "Monitoring"
  })
}

resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "cpu-high-cost-proxy-cvd-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.lab.id]
  description         = "Fires when VM CPU exceeds 80% over 15 minutes. Early-warning proxy for cost anomalies that take 24-72h to surface in Cost Management."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.metric_alerts.id
  }

  tags = merge(var.tags, {
    costcategory = "Monitoring"
  })
}