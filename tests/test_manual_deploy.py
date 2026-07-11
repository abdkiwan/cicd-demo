import importlib.util
import sys
from pathlib import Path


def test_manual_deploy_script_can_import_app_modules():
    repo_root = Path(__file__).resolve().parents[1]
    script_path = repo_root / "scripts" / "manual_deploy.py"

    spec = importlib.util.spec_from_file_location("manual_deploy", script_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None

    spec.loader.exec_module(module)

    assert module.ROOT_DIR == repo_root
    assert "app.deploy_helpers" in sys.modules
