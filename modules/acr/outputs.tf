output "id" {
  description = "Resource ID of the Azure Container Registry."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Name of the Azure Container Registry."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Fully qualified login server for the Azure Container Registry."
  value       = azurerm_container_registry.this.login_server
}

output "resource_group_name" {
  description = "Resource group containing the Azure Container Registry."
  value       = azurerm_container_registry.this.resource_group_name
}

output "location" {
  description = "Primary Azure region of the Container Registry."
  value       = azurerm_container_registry.this.location
}

output "sku" {
  description = "SKU of the Azure Container Registry."
  value       = azurerm_container_registry.this.sku
}

output "geo_replication_regions" {
  description = "Azure regions configured as geo-replicas."
  value       = var.geo_replication_regions
}
output "private_endpoint_ip" {
  description = "Private IP address of the registry private endpoint."
  value       = azurerm_private_endpoint.acr.private_service_connection[0].private_ip_address
}

output "virtual_network_id" {
  description = "ID of the virtual network hosting the registry private endpoint."
  value       = azurerm_virtual_network.this.id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace receiving registry logs."
  value       = azurerm_log_analytics_workspace.this.id
}

output "acr_image_task_service_principal_app_id" {
  description = "Application ID for the least-privilege ACR image task service principal."
  value       = var.acr_image_tasks_service_principal_enabled ? azuread_application.acr_image_tasks[0].client_id : null
}

output "acr_image_task_service_principal_object_id" {
  description = "Object ID for the least-privilege ACR image task service principal."
  value       = var.acr_image_tasks_service_principal_enabled ? azuread_service_principal.acr_image_tasks[0].object_id : null
}

output "acr_image_task_service_principal_client_secret" {
  description = "Client secret for the least-privilege ACR image task service principal."
  value       = var.acr_image_tasks_service_principal_enabled ? azuread_service_principal_password.acr_image_tasks[0].value : null
  sensitive   = true
}
