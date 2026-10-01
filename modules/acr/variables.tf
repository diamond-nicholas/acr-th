variable "tenant_id" {
  description = "Microsoft Entra tenant ID to deploy into."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "state_resource_group_name" {
  description = "Resource group of the remote state storage account. Read by Terragrunt."
  type        = string
}

variable "state_storage_account_name" {
  description = "Storage account holding remote state. Read by Terragrunt."
  type        = string
}

variable "state_container_name" {
  description = "Blob container holding remote state. Read by Terragrunt."
  type        = string
}

variable "acr_name" {
  description = "Globally unique Azure Container Registry name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.acr_name))
    error_message = "ACR name must contain only lowercase letters and numbers and be between 5 and 50 characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group containing the Azure Container Registry."
  type        = string
}

variable "location" {
  description = "Primary Azure region for the Container Registry."
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "geo_replication_regions" {
  description = "Additional Azure regions where the Premium ACR will be geo-replicated."
  type        = set(string)
  default     = []

  validation {
    condition     = !contains(var.geo_replication_regions, var.location)
    error_message = "Geo-replication regions must not contain the primary ACR region."
  }
}

variable "tags" {
  description = "Additional tags to apply to Azure resources."
  type        = map(string)
  default     = {}
}

# Network

variable "vnet_address_space" {
  description = "Address space of the virtual network hosting the registry private endpoint."
  type        = list(string)
}

variable "private_endpoint_subnet_prefix" {
  description = "Address prefix of the subnet for private endpoints."
  type        = string
}

variable "management_subnet_prefix" {
  description = "Address prefix of the private management VM subnet."
  type        = string
}

variable "bastion_subnet_prefix" {
  description = "Address prefix of the Azure Bastion subnet."
  type        = string
}

# ACR

variable "untagged_manifest_retention_days" {
  description = "Days to keep untagged manifests before they are purged."
  type        = number
  default     = 7

  validation {
    condition     = var.untagged_manifest_retention_days >= 0 && var.untagged_manifest_retention_days <= 365
    error_message = "Retention must be between 0 and 365 days."
  }
}

variable "log_retention_days" {
  description = "Days to keep registry logs in Log Analytics."
  type        = number
  default     = 30
}

variable "acr_push_principal_ids" {
  description = "Object IDs granted AcrPush, for example CI identities."
  type        = set(string)
  default     = []
}

variable "acr_pull_principal_ids" {
  description = "Object IDs granted AcrPull, for example AKS kubelet identities."
  type        = set(string)
  default     = []
}

variable "acr_image_tasks_service_principal_enabled" {
  description = "Create a dedicated service principal with least-privilege access for ACR image task operations."
  type        = bool
  default     = false
}

variable "acr_image_tasks_service_principal_name" {
  description = "Display name for the service principal that manages ACR image tasks."
  type        = string
  default     = "sp-acr-image-tasks"
}

# Management VM

variable "vm_admin_username" {
  description = "Administrator username for the private management VM."
  type        = string
}

variable "vm_size" {
  description = "SKU for the private management VM. Choose a size available in the target region."
  type        = string
  default     = "Standard_DC1ds_v3"
}

variable "vm_admin_ssh_public_key" {
  description = "SSH public key used to access the private management VM."
  type        = string
  sensitive   = true
}

variable "github_runner_enabled" {
  description = "Whether the VM should register a GitHub self-hosted runner on boot."
  type        = bool
  default     = false
}

variable "github_runner_url" {
  description = "GitHub repository or organization URL for the runner."
  type        = string
  default     = ""
}

variable "github_runner_token" {
  description = "GitHub runner registration token. Keep this out of source control."
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_runner_name" {
  description = "Name to register the GitHub runner with."
  type        = string
  default     = "vm-self-hosted-runner"
}

variable "github_runner_labels" {
  description = "Comma-separated labels for the GitHub runner."
  type        = string
  default     = "self-hosted,linux,x64"
}
