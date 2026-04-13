# ============================================================
# cost_views.tf
# ============================================================
# Saved Cost Analysis views at the subscription scope.
#
# These appear in: Subscription -> Cost Management ->
# Cost analysis -> View dropdown.
#
# Mirrors the three views built manually in the portal phase:
#   1. BizOwner-CostCategory  (Monthly, grouped by tag 'costcategory')
#   2. BizOwner-RGroupDaily   (Daily,   grouped by ResourceGroupName)
#   3. BizOwner-ServiceDaily  (Daily,   grouped by ServiceName)
#
# All three use:
#   - report_type = Usage         (actual cost, not amortized)
#   - timeframe   = MonthToDate   (resets on the 1st of each month)
#   - chart_type  = Area          (matches the portal screenshots)
#   - accumulated = true          (running total across the period)
# ============================================================

# ---- 1. Cost by Cost Category tag (Monthly) ----------------
resource "azurerm_subscription_cost_management_view" "biz_owner_cost_category" {
  name             = "BizOwner-CostCategory"
  display_name     = "BizOwner-CostCategory"
  subscription_id  = data.azurerm_subscription.current.id
  chart_type       = "Area"
  accumulated      = true
  report_type      = "Usage"
  timeframe        = "MonthToDate"

  dataset {
    granularity = "Monthly"

    aggregation {
      name        = "totalCost"
      column_name = "Cost"
    }
  }

  pivot {
    type = "TagKey"
    name = "costcategory"
  }

  pivot {
    type = "Dimension"
    name = "ServiceName"
  }

  pivot {
    type = "Dimension"
    name = "ResourceGroupName"
  }
}

# ---- 2. Cost by Resource Group (Daily) ---------------------
resource "azurerm_subscription_cost_management_view" "biz_owner_rgroup_daily" {
  name             = "BizOwner-RGroupDaily"
  display_name     = "BizOwner-RGroupDaily"
  subscription_id  = data.azurerm_subscription.current.id
  chart_type       = "Area"
  accumulated      = true
  report_type      = "Usage"
  timeframe        = "MonthToDate"

  dataset {
    granularity = "Daily"

    aggregation {
      name        = "totalCost"
      column_name = "Cost"
    }
  }

  pivot {
    type = "Dimension"
    name = "ResourceGroupName"
  }

  pivot {
    type = "Dimension"
    name = "ServiceName"
  }

  pivot {
    type = "Dimension"
    name = "ResourceLocation"
  }
}

# ---- 3. Cost by Service (Daily) ----------------------------
resource "azurerm_subscription_cost_management_view" "biz_owner_service_daily" {
  name             = "BizOwner-ServiceDaily"
  display_name     = "BizOwner-ServiceDaily"
  subscription_id  = data.azurerm_subscription.current.id
  chart_type       = "Area"
  accumulated      = true
  report_type      = "Usage"
  timeframe        = "MonthToDate"

  dataset {
    granularity = "Daily"

    aggregation {
      name        = "totalCost"
      column_name = "Cost"
    }
  }

  pivot {
    type = "Dimension"
    name = "ServiceName"
  }

  pivot {
    type = "Dimension"
    name = "ResourceGroupName"
  }

  pivot {
    type = "Dimension"
    name = "ResourceLocation"
  }
}