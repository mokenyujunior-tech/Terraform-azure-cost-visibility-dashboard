resource "azurerm_application_insights" "func" {
  name                = "appi-${var.project_short_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  retention_in_days   = 30

  tags = merge(var.tags, {
    costcategory = "Monitoring"
  })
}
