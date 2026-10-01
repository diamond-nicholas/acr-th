locals {
  var_file = abspath(get_env("TG_VAR_FILE"))
  vars     = jsondecode(read_tfvars_file(local.var_file))
}

remote_state {
  backend = "azurerm"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    tenant_id            = local.vars.tenant_id
    subscription_id      = local.vars.subscription_id
    resource_group_name  = local.vars.state_resource_group_name
    storage_account_name = local.vars.state_storage_account_name
    container_name       = local.vars.state_container_name
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    use_azuread_auth     = true
  }
}

terraform {
  extra_arguments "var_file" {
    commands  = get_terraform_commands_that_need_vars()
    arguments = ["-var-file=${local.var_file}"]
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOT
provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
EOT
}
