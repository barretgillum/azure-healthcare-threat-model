output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.healthcare.name
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.healthcare.name
}

output "web_subnet_id" {
  description = "Resource ID of the web subnet"
  value       = azurerm_subnet.web.id
}

output "api_subnet_id" {
  description = "Resource ID of the API subnet"
  value       = azurerm_subnet.api.id
}

output "data_subnet_id" {
  description = "Resource ID of the data subnet"
  value       = azurerm_subnet.data.id
}

output "api_managed_identity_principal_id" {
  description = "Principal ID of the API user-assigned managed identity"
  value       = azurerm_user_assigned_identity.api.principal_id
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.healthcare.name
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.healthcare.name
}