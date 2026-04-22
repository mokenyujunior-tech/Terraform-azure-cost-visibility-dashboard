output "resource_group_name" {
  description = "Main resource group."
  value       = azurerm_resource_group.main.name
}

output "function_app_name" {
  description = "Linux Function App running the weekly cost report."
  value       = azurerm_linux_function_app.func.name
}

output "api_connection_name" {
  description = "Outlook.com API connection that must be manually authorized once after first apply."
  value       = azurerm_api_connection.outlook.name
}

output "logic_app_workflow_id" {
  description = "Resource ID of the deployed Logic App workflow."
  value       = local.logic_app_id
}

output "action_group_name" {
  description = "Monitor Action Group that fires the Logic App."
  value       = azurerm_monitor_action_group.cost_alerts.name
}

output "post_apply_steps" {
  description = "One-time manual steps required after the first successful apply."
  value       = <<-EOT

    ============================================================
    POST-APPLY MANUAL STEPS (one-time)
    ============================================================

    1. Authorize the Outlook.com connection:
         Portal > Resource group ${azurerm_resource_group.main.name}
               > ${azurerm_api_connection.outlook.name}
               > Edit API connection > Authorize > sign in
               > Save

    2. Wait ~5 minutes for the Function App's first cold start
       (Linux Python builds via Oryx on first deploy).

    3. Test the function:
         Portal > Function App ${azurerm_linux_function_app.func.name}
               > Functions > WeeklyCostReport
               > Code + Test > Test/Run

    4. Verify the email arrived in ${var.owner_email}.

    ============================================================
  EOT
  sensitive   = true
}

output "vm_public_ip" {
  description = "Public IP of the lab VM. SSH with: ssh -i ~/.ssh/cvd_vm_key mokadmin@<this-ip>"
  value       = azurerm_public_ip.vm.ip_address
}

output "vm_ssh_private_key" {
  description = "Private SSH key for the lab VM. Retrieve with: terraform output -raw vm_ssh_private_key"
  value       = tls_private_key.vm_ssh.private_key_pem
  sensitive   = true
}

output "vm_ssh_command" {
  description = "Ready-to-paste SSH command for the lab VM."
  value       = "ssh -i ~/.ssh/cvd_vm_key ${var.vm_admin_username}@${azurerm_public_ip.vm.ip_address}"
}
