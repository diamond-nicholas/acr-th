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
