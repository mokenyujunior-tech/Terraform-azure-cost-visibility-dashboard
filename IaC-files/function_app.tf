resource "azurerm_service_plan" "func" {
  name                = "asp-${var.project_short_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = merge(var.tags, {
    costcategory = "Automation"
  })
}

resource "azurerm_linux_function_app" "func" {
  name                = "func-${var.project_short_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.func.id

  storage_account_name       = azurerm_storage_account.func.name
  storage_account_access_key = azurerm_storage_account.func.primary_access_key

  https_only                    = true
  public_network_access_enabled = true
  functions_extension_version   = "~4"

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.func.connection_string
    application_insights_key               = azurerm_application_insights.func.instrumentation_key
    ftps_state                              = "Disabled"
    minimum_tls_version                     = "1.2"

    application_stack {
      python_version = "3.11"
    }

    cors {
      allowed_origins     = ["https://portal.azure.com"]
      support_credentials = false
    }
  }

  app_settings = {
    # Explicit runtime — safety belt if Azure auto-detect ever changes.
    "FUNCTIONS_WORKER_RUNTIME" = "python"

    # Run from the zipped package uploaded by Terraform.
    "WEBSITE_RUN_FROM_PACKAGE" = "https://${azurerm_storage_account.func.name}.blob.core.windows.net/${azurerm_storage_container.releases.name}/${azurerm_storage_blob.function_zip.name}${data.azurerm_storage_account_blob_container_sas.releases.sas}"

    # Force the function host to reload when the zip's MD5 changes.
    "FUNCTION_PACKAGE_HASH" = data.archive_file.function_zip.output_md5

    # Custom settings consumed by the Python code.
    "AZURE_SUBSCRIPTION_ID" = var.subscription_id
    "LOGIC_APP_URL"         = local.logic_app_callback_url
    "WEEKLY_REPORT_CRON"    = var.weekly_report_cron

    # Application Insights wiring.
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.func.connection_string

    # Required for Python Functions v2 model.
    "AzureWebJobsFeatureFlags" = "EnableWorkerIndexing"

    # Recommended for Linux Consumption: remote Oryx build.
    "ENABLE_ORYX_BUILD"              = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  tags = merge(var.tags, {
    costcategory = "Automation"
  })

  depends_on = [
    azurerm_resource_group_template_deployment.logic_app,
  ]
}
