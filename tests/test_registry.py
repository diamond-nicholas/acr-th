import os

import pytest
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerregistry import ContainerRegistryManagementClient


@pytest.mark.live
@pytest.mark.skipif(
    not os.environ.get("RUN_LIVE_ACR_TESTS", "").lower() in {"1", "true", "yes"},
    reason="Live registry checks run only when RUN_LIVE_ACR_TESTS=true",
)
def test_registry_configuration():
    subscription_id = os.environ["AZURE_SUBSCRIPTION_ID"]
    acr_name = "westeuropeprodacr01"

    credential = DefaultAzureCredential()
    client = ContainerRegistryManagementClient(credential, subscription_id)
    registry = client.registries.get("rg-acr-prod-westeurope", acr_name)

    assert registry.location.lower() == "westeurope"
    assert registry.sku.name == "Premium"
    assert registry.public_network_access == "Disabled"
    assert registry.admin_user_enabled is False
    assert registry.anonymous_pull_enabled is False
    assert registry.zone_redundancy == "Enabled"

    replicas = list(client.replications.list("rg-acr-prod-westeurope", acr_name))
    assert any(rep.location.lower() == "northeurope" for rep in replicas)
