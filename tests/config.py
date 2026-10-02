import ast
import os
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROD_TFVARS = ROOT / "prod.tfvars"


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

        if value.startswith('"') and value.endswith('"'):
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


def load_runtime_config():
    tfvars = parse_tfvars(PROD_TFVARS)
    env = os.environ

    return {
        "tenant_id": env.get("AZURE_TENANT_ID") or tfvars.get("tenant_id"),
        "subscription_id": env.get("AZURE_SUBSCRIPTION_ID") or tfvars.get("subscription_id"),
        "acr_name": env.get("ACR_NAME") or tfvars.get("acr_name"),
        "resource_group_name": env.get("RESOURCE_GROUP") or tfvars.get("resource_group_name"),
        "location": tfvars.get("location", "").lower(),
        "environment": env.get("DEPLOYMENT_ENVIRONMENT") or tfvars.get("environment", "prod"),
    }
