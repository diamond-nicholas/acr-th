from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SMOKE_WORKFLOW = ROOT / ".github" / "workflows" / "acr-push-smoke-test.yml"


def test_workflow_imports_base_image_before_validation():
    text = SMOKE_WORKFLOW.read_text()

    assert "push:" in text
    assert "branches: [main]" in text
    assert "bash scripts/import-base-image.sh" in text
    assert "Import pinned base image into ACR" in text
    assert "az acr repository delete" in text
    assert "TARGET_IMAGE" in text
    assert "EXPECTED_DIGEST" in text
    assert "python -m pytest -q tests" not in text


def test_workflow_uses_self_hosted_runner_and_oidc():
    text = SMOKE_WORKFLOW.read_text()

    assert "runs-on: [self-hosted, linux, x64]" in text
    assert "azure/login@v2" in text
    assert "AZURE_CLIENT_ID" in text
    assert "AZURE_TENANT_ID" in text
    assert "AZURE_SUBSCRIPTION_ID" in text
