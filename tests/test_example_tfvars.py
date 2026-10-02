import ast
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TFVARS_PATH = ROOT / "example.tfvars"


def parse_tfvars(path: Path):
    values = {}

    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = [part.strip() for part in line.split("=", 1)]
        value = value.strip()

        if not value:
            raise ValueError(f"Empty value for {key!r} in {path.name}")

        if value.startswith("\"") and value.endswith("\""):
            values[key] = ast.literal_eval(value)
            continue

        if value.lower() == "true":
            values[key] = True
            continue

        if value.lower() == "false":
            values[key] = False
            continue

        if re.fullmatch(r"-?\d+", value):
            values[key] = int(value)
            continue

        if value.startswith("[") and value.endswith("]"):
            normalized = value.replace("true", "True").replace("false", "False")
            values[key] = ast.literal_eval(normalized)
            continue

        values[key] = value.strip('"')

    return values


def test_example_tfvars_is_complete_and_valid():
    tfvars = parse_tfvars(TFVARS_PATH)

    required_keys = {
        "tenant_id",
        "subscription_id",
        "acr_name",
        "resource_group_name",
        "location",
        "environment",
        "vnet_address_space",
        "private_endpoint_subnet_prefix",
        "management_subnet_prefix",
        "bastion_subnet_prefix",
        "vm_admin_username",
        "vm_size",
        "vm_admin_ssh_public_key",
    }

    missing = sorted(required_keys - set(tfvars))
    assert not missing, f"Missing required keys: {missing}"
    assert tfvars["location"] == "West Europe"
    assert tfvars["acr_name"] == "westeuropeprodacr01"
    assert tfvars["resource_group_name"] == "rg-acr-prod-westeurope"
    assert tfvars["management_subnet_prefix"].endswith("/27")
    assert tfvars["bastion_subnet_prefix"].endswith("/26")
    assert tfvars["vm_admin_ssh_public_key"].startswith("ssh-rsa ")
    assert tfvars["github_actions_oidc_subject"].startswith("repo:")
