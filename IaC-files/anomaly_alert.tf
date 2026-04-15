# ============================================================
# anomaly_alert.tf
# ============================================================
# Daily cost anomaly alert at the subscription scope.
# Equivalent to the portal: Cost Management -> Cost alerts ->
# + Add -> Anomaly.
#
# Deployed via azapi_resource because azurerm has no native
# resource for Microsoft.CostManagement/scheduledActions of
# kind 'InsightAlert' as of provider v3.110.
#
# Detection runs daily ~36 hours after end-of-day UTC.
# When an anomaly is detected (a daily cost outside the
# 60-day forecast range) an email is sent immediately to
# var.owner_email.
# ============================================================

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

  # startDate uses timestamp() which would otherwise force
  # replacement on every plan. To intentionally update the
  # alert later, comment this out, apply, then uncomment.
  lifecycle {
    ignore_changes = [body]
  }
}