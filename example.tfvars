tenant_id       = "12345"
subscription_id = "00000000-0000-0000-0000-000000000000"

state_resource_group_name  = "rg-tfstate-example"
state_storage_account_name = "contosotfstate01"
state_container_name       = "tfstate"

acr_name            = "contosoprodacr01"
resource_group_name = "rg-acr-prod-we"
location            = "West Europe"
environment         = "prod"

geo_replication_regions = [
  "North Europe"
]

tags = {
  project    = "container-platform"
  owner      = "platform-team"
  costcenter = "platform"
}

vnet_address_space             = ["10.40.0.0/24"]
private_endpoint_subnet_prefix = "10.40.0.0/27"

untagged_manifest_retention_days = 7
log_retention_days               = 30

acr_push_principal_ids = []
acr_pull_principal_ids = []
acr_image_tasks_service_principal_enabled = true
acr_image_tasks_service_principal_name = "sp-eastusprodacr01-image-tasks"

github_runner_enabled = true
github_runner_url = "https://github.com/<organization>/<repository>"
github_runner_token = "<replace-with-github-runner-registration-token>"
github_runner_name = "vm-eastusprodacr01-management"
github_runner_labels = "self-hosted,linux,x64"

vm_admin_username = "adminxx"
vm_size = "Standard_DC1ds_v3"
vm_admin_ssh_public_key =
