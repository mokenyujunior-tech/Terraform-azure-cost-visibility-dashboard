resource "azapi_resource" "cost_anomaly_alert" {
  type      = "Microsoft.CostManagement/scheduledActions@2022-10-01"
  name      = "mokcloud-daily-anomaly"
  parent_id = data.azurerm_subscription.current.id

  body = jsonencode({
    kind = "InsightAlert"
    properties = {
      displayName = "MOKCLOUD Daily Anomaly"
      status      = "Enabled"
      viewId      = "${data.azurerm_subscription.current.id}/providers/Microsoft.CostManagement/views/ms:DailyAnomalyByResourceGroup"
      notification = {
        to       = [var.owner_email]
        subject  = "Cost anomaly detected in MOKCLOUD subscription"
        message  = "Daily anomaly detection flagged unusual spending. Open Cost Analysis to review."
        language = "en"
      }
      schedule = {
        frequency  = "Daily"
        hourOfDay  = 12
        dayOfMonth = 0
        startDate  = formatdate("YYYY-MM-DD'T'00:00:00'Z'", timestamp())
        endDate    = formatdate("YYYY-MM-DD'T'00:00:00'Z'", timeadd(timestamp(), "43800h"))
      }
    }
  })

  lifecycle {
    ignore_changes = [body]
  }
}