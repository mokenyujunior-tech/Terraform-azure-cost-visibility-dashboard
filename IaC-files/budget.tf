resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "monthly-cost-budget-${var.monthly_budget_amount}"
  subscription_id = "/subscriptions/${var.subscription_id}"

  amount     = var.monthly_budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = "2026-04-01T00:00:00Z"
    end_date   = "2030-01-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.owner_email]
    contact_groups = [azurerm_monitor_action_group.cost_alerts.id]
  }

  notification {
    enabled        = true
    threshold      = 75
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.owner_email]
    contact_groups = [azurerm_monitor_action_group.cost_alerts.id]
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.owner_email]
    contact_groups = [azurerm_monitor_action_group.cost_alerts.id]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.owner_email]
    contact_groups = [azurerm_monitor_action_group.cost_alerts.id]
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}
