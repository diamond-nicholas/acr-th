resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_container_registry" "this" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  sku = "Premium"

  zone_redundancy_enabled = true

  admin_enabled          = false
  anonymous_pull_enabled = false

  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"
  data_endpoint_enabled         = true
  export_policy_enabled         = false #images can't be copied out of registory

  retention_policy_in_days = var.untagged_manifest_retention_days

  dynamic "georeplications" {
    for_each = var.geo_replication_regions

    content {
      location                        = georeplications.value
      zone_redundancy_enabled         = true
      global_endpoint_routing_enabled = true
      tags                            = merge(local.common_tags, { role = "geo-replica" })
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = local.common_tags
}

resource "azurerm_management_lock" "acr" {
  name       = "lock-${var.acr_name}"
  scope      = azurerm_container_registry.this.id
  lock_level = "CanNotDelete"
  notes      = "Protects the production registry from accidental deletion."
}


resource "azurerm_bastion_host" "this" {
  name                = "bas-${var.acr_name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  sku = "Basic"

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = local.common_tags
}

resource "azurerm_linux_virtual_machine" "management" {
  name                = "vm-${var.acr_name}-management"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = var.vm_size

  admin_username = var.vm_admin_username

  network_interface_ids = [
    azurerm_network_interface.management.id
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/templates/management_vm_user_data.tftpl", {
    vm_admin_username     = var.vm_admin_username
    github_runner_enabled = var.github_runner_enabled
    github_runner_url     = var.github_runner_url
    github_runner_token   = var.github_runner_token
    github_runner_name    = var.github_runner_name
    github_runner_labels  = var.github_runner_labels
  }))

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azuread_application.acr_image_tasks,
    azuread_service_principal.acr_image_tasks,
    azuread_application_federated_identity_credential.acr_image_tasks_github,
    azurerm_role_assignment.acr_image_tasks,
  ]

  tags = local.common_tags
}