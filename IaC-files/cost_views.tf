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

    # Main chart's "Group by" -> tag named 'costcategory'
    grouping {
      type = "TagKey"
      name = "costcategory"
    }
  }

  # Three sub-views at the bottom of the page
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

    # Main chart's "Group by" -> Resource group name
    grouping {
      type = "Dimension"
      name = "ResourceGroupName"
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

    # Main chart's "Group by" -> Service name
    grouping {
      type = "Dimension"
      name = "ServiceName"
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