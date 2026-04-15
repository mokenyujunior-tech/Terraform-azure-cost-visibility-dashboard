# ============================================================
# metric_alert.tf
# ============================================================
# Near-real-time CPU metric alert on the lab VM.
#
# Acts as the early-warning leg of the cost monitoring story:
# Cost Management has a 24-72 hour data delay, anomaly alerts
# wait 36 hours after end-of-day. This alert evaluates every
# 5 minutes over a 15-minute window, so a runaway workload is
# detected in 5-15 minutes instead of a day later.
#
# Triggering test (run on the VM via SSH):
#   sudo apt-get install -y stress
#   stress --cpu 2 --timeout 600
# Email arrives ~5 minutes after CPU sustains > 80%.
# ============================================================

# Dedicated action group for operational/metric alerts. Kept
# separate from ag-cost-alerts so muting one doesn't silence
# the other.
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