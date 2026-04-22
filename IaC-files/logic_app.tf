data "azurerm_managed_api" "outlook" {
  name     = "outlook"
  location = azurerm_resource_group.main.location
}

resource "azurerm_api_connection" "outlook" {
  name                = "api-outlook-${var.project_short_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  managed_api_id      = data.azurerm_managed_api.outlook.id
  display_name        = "Outlook.com (${var.owner_email})"

  tags = merge(var.tags, {
    costcategory = "Automation"
  })

  lifecycle {
    ignore_changes = [
      parameter_values,
    ]
  }
}

resource "azurerm_resource_group_template_deployment" "logic_app" {
  name                = "la-cost-alert-emailer-${var.project_short_name}-${random_string.suffix.result}-deploy"
  resource_group_name = azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  parameters_content = jsonencode({
    workflowName = {
      value = "la-cost-alert-emailer-${var.project_short_name}-${random_string.suffix.result}"
    }
    location = {
      value = azurerm_resource_group.main.location
    }
    ownerEmail = {
      value = var.owner_email
    }
  })

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"

    parameters = {
      workflowName = { type = "String" }
      location     = { type = "String" }
      ownerEmail   = { type = "String" }
    }

    resources = [
      {
        type       = "Microsoft.Logic/workflows"
        apiVersion = "2019-05-01"
        name       = "[parameters('workflowName')]"
        location   = "[parameters('location')]"
        tags = {
          project      = "cost-visibility"
          environment  = "dev"
          deployment   = "terraform"
          owner        = "mokcloud"
          department   = "IT"
          costcategory = "Automation"
        }
        properties = {
          state = "Enabled"
          definition = {
            "$schema"      = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
            contentVersion = "1.0.0.0"
            parameters = {
              "$connections" = {
                defaultValue = {}
                type         = "Object"
              }
            }
            triggers = {
              manual = {
                type = "Request"
                kind = "Http"
                inputs = {
                  schema = {
                    type = "object"
                    properties = {
                      schemaId = { type = "string" }
                      data = {
                        type = "object"
                        properties = {
                          essentials = {
                            type = "object"
                            properties = {
                              alertRule     = { type = "string" }
                              severity      = { type = "string" }
                              firedDateTime = { type = "string" }
                              description   = { type = "string" }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            actions = {
              Send_an_email_V2 = {
                type = "ApiConnection"
                inputs = {
                  host = {
                    connection = {
                      name = "@parameters('$connections')['outlook']['connectionId']"
                    }
                  }
                  method = "post"
                  path   = "/v2/Mail"
                  body = {
                    To      = "[parameters('ownerEmail')]"
                    Subject = "@{coalesce(triggerBody()?['data']?['essentials']?['alertRule'], 'Cost Visibility Dashboard')}"
                    Body    = "<p>@{coalesce(triggerBody()?['data']?['essentials']?['description'], 'Cost alert fired.')}</p><p>Severity: @{coalesce(triggerBody()?['data']?['essentials']?['severity'], 'n/a')}</p>"
                    Importance = "Normal"
                  }
                }
                runAfter = {}
              }
            }
            outputs = {}
          }
          parameters = {
            "$connections" = {
              value = {
                outlook = {
                  connectionId   = azurerm_api_connection.outlook.id
                  connectionName = "outlook"
                  id             = data.azurerm_managed_api.outlook.id
                }
              }
            }
          }
        }
      }
    ]

    outputs = {
      callbackUrl = {
        type  = "string"
        value = "[listCallbackUrl(concat(resourceId('Microsoft.Logic/workflows', parameters('workflowName')), '/triggers/manual'), '2019-05-01').value]"
      }
      workflowId = {
        type  = "String"
        value = "[resourceId('Microsoft.Logic/workflows', parameters('workflowName'))]"
      }
    }
  })

  depends_on = [
    azurerm_api_connection.outlook,
  ]
}

locals {
  logic_app_callback_url = jsondecode(azurerm_resource_group_template_deployment.logic_app.output_content).callbackUrl.value
  logic_app_id           = jsondecode(azurerm_resource_group_template_deployment.logic_app.output_content).workflowId.value
}
