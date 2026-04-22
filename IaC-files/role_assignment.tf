data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "func_cost_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Cost Management Reader"
  principal_id         = azurerm_linux_function_app.func.identity[0].principal_id

  skip_service_principal_aad_check = true
}
