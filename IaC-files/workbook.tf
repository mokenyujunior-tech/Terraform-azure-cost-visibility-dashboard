resource "random_uuid" "workbook" {}

resource "azurerm_application_insights_workbook" "cost_overview" {
  name                = random_uuid.workbook.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  display_name        = "Cost Visibility Dashboard"
  source_id           = "azure monitor"
  category            = "workbook"

  data_json = file("${path.module}/workbook/cost_overview.json")

  tags = merge(var.tags, {
    costcategory = "Monitoring"
  })
}
