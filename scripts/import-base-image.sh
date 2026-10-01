#!/usr/bin/env bash
set -euo pipefail

ACR_NAME="${ACR_NAME:-}"
SOURCE_IMAGE="${SOURCE_IMAGE:-mcr.microsoft.com/azurelinux/base/core:3.0}"
TARGET_IMAGE="${TARGET_IMAGE:-base/azurelinux:3.0}"
FORCE="${FORCE:-false}"

usage() {
  cat <<EOF
Usage: $(basename "$0")

Imports a public Linux base image into Azure Container Registry.

Environment variables:
  ACR_NAME             Target registry name (required)
  SOURCE_IMAGE         Source image reference (default: ${SOURCE_IMAGE})
  TARGET_IMAGE         Target repository:tag (default: ${TARGET_IMAGE})
  ARM_SUBSCRIPTION_ID  Subscription containing the registry (optional)
  FORCE                Overwrite an existing tag when "true" (default: ${FORCE})
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "${ACR_NAME}" ]]; then
  echo "Error: ACR_NAME is required." >&2
  usage >&2
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Error: Azure CLI (az) is not installed or not on PATH." >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Error: not logged in. Run 'az login --tenant <tenant-id>' first." >&2
  exit 1
fi

subscription_args=()
if [[ -n "${ARM_SUBSCRIPTION_ID:-}" ]]; then
  subscription_args=(--subscription "${ARM_SUBSCRIPTION_ID}")
fi

import_args=(
  --name "${ACR_NAME}"
  --source "${SOURCE_IMAGE}"
  --image "${TARGET_IMAGE}"
)
if [[ "${FORCE}" == "true" ]]; then
  import_args+=(--force)
fi

echo "Importing ${SOURCE_IMAGE} into ${ACR_NAME}.azurecr.io/${TARGET_IMAGE}"

az acr import "${import_args[@]}" "${subscription_args[@]+"${subscription_args[@]}"}"

az acr repository show \
  --name "${ACR_NAME}" \
  --image "${TARGET_IMAGE}" \
  --query "{digest: digest, createdTime: createdTime}" \
  --output table \
  "${subscription_args[@]+"${subscription_args[@]}"}" \
  || echo "Import succeeded; tag lookup skipped (registry data plane not reachable from this network)."

echo "Done: ${ACR_NAME}.azurecr.io/${TARGET_IMAGE}"
