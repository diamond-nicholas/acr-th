from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "acr-push-smoke-test.yml"


def test_workflow_imports_base_image_before_validation():
    text = WORKFLOW.read_text()

    assert "bash scripts/import-base-image.sh" in text
    assert "Import pinned base image into ACR" in text
    assert "az acr repository delete" in text
    assert "TARGET_IMAGE" in text
    assert "EXPECTED_DIGEST" in text


def test_workflow_runs_pytest_in_ci():
    text = WORKFLOW.read_text()

    assert "python -m pytest -q tests" in text
