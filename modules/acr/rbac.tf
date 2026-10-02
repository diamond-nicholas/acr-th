resource "azurerm_role_assignment" "acr_push" {
  for_each = var.acr_push_principal_ids

  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "management_vm_acr_push" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_linux_virtual_machine.management.identity[0].principal_id

  depends_on = [azurerm_linux_virtual_machine.management]
}

resource "azurerm_role_assignment" "acr_pull" {
  for_each = var.acr_pull_principal_ids

  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = each.value
}

resource "azurerm_role_definition" "acr_image_tasks" {
  count = var.acr_image_tasks_service_principal_enabled ? 1 : 0

  name        = "ACR Image Task Operator (${var.acr_name})"
  scope       = azurerm_container_registry.this.id
  description = "Least-privilege permissions to manage ACR image tasks and repository content for the registry."

  permissions {
    actions = [
      "Microsoft.ContainerRegistry/registries/read",
      "Microsoft.ContainerRegistry/registries/pull/read",
      "Microsoft.ContainerRegistry/registries/push/write"
    ]
    not_actions = []
  }

  assignable_scopes = [azurerm_container_registry.this.id]
}

resource "azuread_application" "acr_image_tasks" {
  count = var.acr_image_tasks_service_principal_enabled ? 1 : 0

  display_name = var.acr_image_tasks_service_principal_name
  owners       = []
}

resource "azuread_service_principal" "acr_image_tasks" {
  count = var.acr_image_tasks_service_principal_enabled ? 1 : 0

  client_id = azuread_application.acr_image_tasks[0].client_id
  owners    = []
}

resource "azurerm_role_assignment" "acr_image_tasks" {
  count = var.acr_image_tasks_service_principal_enabled ? 1 : 0

  scope              = azurerm_container_registry.this.id
  role_definition_id = azurerm_role_definition.acr_image_tasks[0].role_definition_resource_id
  principal_id       = azuread_service_principal.acr_image_tasks[0].object_id
}
