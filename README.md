# azure-acr

This repository contains a Terragrunt + Terraform deployment for a private Azure Container Registry with a management VM and Azure Bastion. The current live configuration is a private ACR deployment with a management path separated from the registry network, and it supports a self-hosted GitHub runner running inside the VNet for private registry access.

The design intentionally separates human admin access from application delivery workflows. Azure Bastion is used for operator access to the private management VM, while the runner and pipeline operate within the private network and authenticate to Azure using GitHub repository secrets.

## Current architecture

- Private-only ACR with `public_network_access_enabled = false`
- Private endpoint and private DNS zone for `azurecr.io`
- Management subnet with a Linux VM behind NAT and no public IP
- Azure Bastion for human administrative access
- Azure Policy denying public access, admin user use, anonymous pull, and export
- Terraform remote state stored in a separate Azure Storage account using Entra auth
- Deletion protection via Terraform `prevent_destroy` and an Azure `CanNotDelete` lock
- Optional self-hosted runner installation for private CI jobs

## Security notes

- Secrets must be kept out of source control. Use GitHub repository secrets or another secure secret store for pipeline credentials.
- Keep `*.tfvars` files out of Git.
- The service principal used for registry operations should be least privilege and rotated on a schedule.
- Prefer OIDC or managed identity for future pipeline hardening instead of long-lived service-principal secrets.

## Usage

```bash
cp example.tfvars prod.tfvars
# populate the file with your environment values

az login --tenant <tenant-id>

cd live/prod/westeurope/acr

TG_VAR_FILE=../../../../prod.tfvars terragrunt plan
TG_VAR_FILE=../../../../prod.tfvars terragrunt apply
```

`TG_VAR_FILE` is used because Terragrunt also needs the tfvars values when configuring the remote backend.

## Network access model

```text
Human:  Administrator → Bastion → Management VM → ACR private endpoint
CI:     GitHub self-hosted runner → private network → ACR private endpoint
Registry:  Private network only; no public registry endpoints
```

## Private CI / image push flow

The repository includes a GitHub Actions workflow that runs on a self-hosted runner inside the private network and authenticates to Azure using GitHub repository secrets.

This pattern is intentionally aligned with a private ACR deployment model:

- the runner is placed inside the same VNet as the registry path
- ACR is reachable only through the private endpoint
- the runner authenticates with the least-privilege Azure service principal
- the workflow pulls a public image, tags it for the private registry, and pushes it to ACR
- a smoke test validates that the registry accepts the pushed image and exposes it in the repository

This is a proven private-network CI pattern for a private registry workload and matches the successful nginx push flow that was validated in this environment.

## Pipeline behavior

This repo includes a GitHub Actions smoke test workflow that:

- authenticates to Azure with service-principal secrets from GitHub
- logs into the private ACR
- pulls `nginx` from Docker Hub
- tags it for the ACR repository
- pushes it to the registry
- confirms the image is available in the target ACR repository

The workflow is designed for a private-network CI model, and it is appropriate when the runner is isolated, patched, and limited to the required registry access path. Secrets remain in GitHub repository secrets rather than in the repository itself.

## Working assumptions

This repo is a sound private-registry baseline and supports a real private CI workflow. It is not yet a fully hardened production CI/CD design, but it is aligned with a legitimate self-hosted private-runner model for Azure Container Registry workloads and has been validated with a successful image push to the private registry.

## Areas to improve

- Replace static Azure client secrets with GitHub OIDC or managed identity where possible.
- Add approval gates and branch protection for registry image pushes.
- Add image scanning and policy enforcement before pushing to production tags.
- Consider tag immutability, retention policies, and image signing for provenance.
- Add monitoring and alerting around ACR push activity, registry events, and runner access.
- Review whether the custom ACR role for image tasks is sufficient for all required task operations.
- Use a dedicated CI workflow identity instead of a broader application registration where possible.
- Add pre-commit checks, linting, and policy validation for Terraform.
- Consider separate production and non-production repositories or naming conventions to reduce accidental promotion risk.

## Destroy

Deletion is protected by Terraform `prevent_destroy` and an Azure `CanNotDelete` lock. Both must be removed before destruction.
