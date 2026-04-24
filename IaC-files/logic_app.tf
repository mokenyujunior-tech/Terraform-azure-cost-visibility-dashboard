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
                    Subject = "⚠️ Azure Cost Alert | @{coalesce(triggerBody()?['data']?['essentials']?['alertRule'], 'Cost Visibility Dashboard')} | @{coalesce(triggerBody()?['data']?['essentials']?['severity'], '')} | @{formatDateTime(utcNow(), 'MMM dd, yyyy')}"
                    Body    = "<div style='font-family:Segoe UI,Arial,sans-serif;max-width:600px;margin:0 auto;'><div style='background:#0078D4;padding:20px;text-align:center;'><h1 style='color:#ffffff;margin:0;font-size:20px;'>Azure Cost Visibility Dashboard</h1><p style='color:#cce4f7;margin:5px 0 0;font-size:13px;'>MOKCLOUD Subscription &mdash; Automated Alert Notification</p></div><div style='padding:24px;background:#ffffff;border:1px solid #e0e0e0;'><h2 style='color:#d83b01;margin:0 0 16px;font-size:18px;'>&#9888; Budget Threshold Breached</h2><table style='width:100%;border-collapse:collapse;font-size:14px;'><tr style='border-bottom:1px solid #f0f0f0;'><td style='padding:10px 0;color:#666;width:40%;'>Alert Rule</td><td style='padding:10px 0;font-weight:600;'>@{coalesce(triggerBody()?['data']?['essentials']?['alertRule'], 'N/A')}</td></tr><tr style='border-bottom:1px solid #f0f0f0;'><td style='padding:10px 0;color:#666;'>Severity</td><td style='padding:10px 0;font-weight:600;'>@{coalesce(triggerBody()?['data']?['essentials']?['severity'], 'N/A')}</td></tr><tr style='border-bottom:1px solid #f0f0f0;'><td style='padding:10px 0;color:#666;'>Fired At</td><td style='padding:10px 0;font-weight:600;'>@{coalesce(triggerBody()?['data']?['essentials']?['firedDateTime'], 'N/A')}</td></tr><tr style='border-bottom:1px solid #f0f0f0;'><td style='padding:10px 0;color:#666;'>Condition</td><td style='padding:10px 0;font-weight:600;'>@{coalesce(triggerBody()?['data']?['essentials']?['monitorCondition'], 'Fired')}</td></tr></table><div style='margin:20px 0;padding:16px;background:#f8f8f8;border-left:4px solid #0078D4;font-size:14px;'><strong>Details:</strong><br/>@{coalesce(triggerBody()?['data']?['essentials']?['description'], 'A cost alert has been triggered on your Azure subscription. Please review your spending in the Azure portal.')}</div><div style='margin:20px 0;'><h3 style='font-size:15px;color:#333;margin:0 0 12px;'>Recommended Actions</h3><p style='font-size:14px;color:#555;margin:4px 0;'>1. Review which services are driving the cost increase</p><p style='font-size:14px;color:#555;margin:4px 0;'>2. Check if any new resources were deployed this month</p><p style='font-size:14px;color:#555;margin:4px 0;'>3. Evaluate if any resources can be scaled down or deallocated</p></div><div style='text-align:center;margin:24px 0;'><a href='https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/costanalysis' style='background:#0078D4;color:#ffffff;padding:12px 28px;text-decoration:none;border-radius:4px;font-weight:600;font-size:14px;display:inline-block;'>View Cost Analysis</a></div><div style='text-align:center;margin:8px 0 20px;'><a href='https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/budgets' style='color:#0078D4;font-size:13px;text-decoration:underline;'>View Budget Details</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href='https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/costanalysis/open/true/scope/%2Fsubscriptions%2Fec289c8e-4873-4660-a368-35309d8ca713' style='color:#0078D4;font-size:13px;text-decoration:underline;'>Resource Breakdown</a></div></div><div style='padding:16px;background:#f5f5f5;border-top:1px solid #e0e0e0;text-align:center;font-size:12px;color:#888;'><p style='margin:4px 0;'>This alert was generated automatically by the Cost Visibility Dashboard.</p><p style='margin:4px 0;'>To adjust thresholds: Cost Management &rarr; Budgets in the Azure portal.</p><p style='margin:4px 0;'>Project: cost-visibility | Tenant: MOKCLOUD | Region: Canada Central</p></div></div>"
                    Importance = "Normal"
                    IsHtml = true
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
