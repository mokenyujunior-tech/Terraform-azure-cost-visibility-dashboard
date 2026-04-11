# ============================================================
# resource_group.tf
# ============================================================
# The main RG that contains every resource in this project,
# plus the random suffix generator used to make resource
# names globally unique.
# ============================================================

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
  numeric = true
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(var.tags, {
    costcategory = "Automation"
  })
}
