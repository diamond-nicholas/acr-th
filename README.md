# azure-acr

Terragrunt setup for a production-oriented Azure Container Registry. Premium ACR in West Europe with a North Europe geo-replica. Public access is disabled, with a VNet, private endpoint, private DNS, Log Analytics, deletion protection, and an NSG allowing HTTPS from the VNet.

A private management VM is accessed through Azure Bastion. Bastion is for **human administration only**; CI/CD will use a dedicated private runner with connectivity to the ACR private endpoint.

Azure Policy on the resource group also denies public access, admin user, anonymous pull, and exports being enabled.

The state storage account is created separately and is not managed here.

## Usage

```bash
cp example.tfvars prod.tfvars
```

Fill in the tenant, subscription, state storage, registry and network values.

```bash
az login --tenant <tenant-id>

cd live/prod/westeurope/acr

TG_VAR_FILE=../../../../prod.tfvars terragrunt plan
TG_VAR_FILE=../../../../prod.tfvars terragrunt apply
```

`TG_VAR_FILE` is used because Terragrunt also needs the tfvars values when configuring the remote backend.

All environment-specific values are in the tfvars file; nothing environment-specific is hardcoded in the module.

## Network

```text
Human:  Administrator → Bastion → Private VM

CI/CD:  Private CI Runner → Private Endpoint → ACR
```

The CI runner is separate from Bastion and will authenticate using Entra/OIDC rather than ACR admin credentials.

## Base Image

```bash
./scripts/import-base-image.sh
```

Uses `az acr import`, so Azure performs the import server-side.

## New Environment

Copy `prod.tfvars` to `dev.tfvars`, change the values, and create:

```text
live/dev/northeurope/acr/terragrunt.hcl
```

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/acr"
}
```

Then run Terragrunt with the appropriate `TG_VAR_FILE`.

## Destroy

Deletion is protected by Terraform `prevent_destroy` and an Azure
`CanNotDelete` lock. Both must be removed before destruction.

## Next Steps

* Private CI runner with OIDC
* Approval-gated deployments
* Defender for Containers
* Image signing with Notation
* Checkov/TFLint
* CMK where required
