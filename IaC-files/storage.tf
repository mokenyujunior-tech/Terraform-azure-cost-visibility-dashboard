# ============================================================
# storage.tf
# ============================================================
# Storage account that the Function App uses for its internal
# coordination (webjobs containers) plus a separate container
# that holds the zipped Python function code.
#
# Lessons baked in:
#   - Storage names must be lowercase, 3-24 chars, no hyphens
#   - LRS is fine for a portfolio project
#   - shared_access_key_enabled stays true because Linux
#     Consumption requires the key on cold start
#   - SAS start date is conservatively in the past so the
#     SAS is valid from any clock drift angle
# ============================================================

resource "azurerm_storage_account" "func" {
  name                     = "st${var.project_short_name}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false

  tags = merge(var.tags, {
    costcategory = "Storage"
  })
}

# Container that holds the zipped Python code.
resource "azurerm_storage_container" "releases" {
  name                  = "function-releases"
  storage_account_name  = azurerm_storage_account.func.name
  container_access_type = "private"
}

# Zip the function_code/ folder on every apply.
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function_code"
  output_path = "${path.module}/build/function_code.zip"

  depends_on = [
    null_resource.pip_install,
  ]
}

# Upload the zip into the releases container.
resource "azurerm_storage_blob" "function_zip" {
  name                   = "function_code_${data.archive_file.function_zip.output_md5}.zip"
  storage_account_name   = azurerm_storage_account.func.name
  storage_container_name = azurerm_storage_container.releases.name
  type                   = "Block"
  source                 = data.archive_file.function_zip.output_path
  content_md5            = data.archive_file.function_zip.output_md5
}

# Read-only SAS URL so the Function App can download the zip
# via WEBSITE_RUN_FROM_PACKAGE on cold start.
data "azurerm_storage_account_blob_container_sas" "releases" {
  connection_string = azurerm_storage_account.func.primary_connection_string
  container_name    = azurerm_storage_container.releases.name
  https_only        = true

  start  = "2024-01-01T00:00:00Z"
  expiry = "2030-01-01T00:00:00Z"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}
