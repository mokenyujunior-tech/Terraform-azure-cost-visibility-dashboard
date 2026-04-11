# ============================================================
# role_assignment.tf
# ============================================================
# Grants the Function App's system-assigned managed identity
# the 'Cost Management Reader' role on the subscription so
# its Python code can call Cost Management REST APIs.
#
# skip_service_principal_aad_check = true handles the fact
# that a freshly-created Managed Identity takes a few seconds
# to propagate to Entra ID before RBAC can see it.
# ============================================================

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "func_cost_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Cost Management Reader"
  principal_id         = azurerm_linux_function_app.func.identity[0].principal_id

  skip_service_principal_aad_check = true
}
