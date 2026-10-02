import os

import pytest
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerregistry import ContainerRegistryManagementClient

from tests.config import load_runtime_config


CONFIG = load_runtime_config()


@pytest.mark.live
@pytest.mark.skipif(
    not os.environ.get("RUN_LIVE_ACR_TESTS", "").lower() in {"1", "true", "yes"},
    reason="Live registry checks run only when RUN_LIVE_ACR_TESTS=true",
)
def test_registry_configuration():
    subscription_id = CONFIG["subscription_id"]
    acr_name = CONFIG["acr_name"]
    resource_group_name = CONFIG["resource_group_name"]

    credential = DefaultAzureCredential()
    client = ContainerRegistryManagementClient(credential, subscription_id)
    registry = client.registries.get(resource_group_name, acr_name)

    assert registry.location.lower() == "eastus"
    assert registry.sku.name == "Premium"
    assert registry.public_network_access == "Disabled"
    assert registry.admin_user_enabled is False
    assert registry.anonymous_pull_enabled is False
    assert registry.zone_redundancy == "Enabled"

    replicas = list(client.replications.list(resource_group_name, acr_name))
    assert replicas == []
