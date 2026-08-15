# tools/tests/conftest.py
import pathlib
import sys

TOOLS_DIR = pathlib.Path(__file__).resolve().parents[1]
REPO_DIR = TOOLS_DIR / "data" / "nihaixia"
sys.path.insert(0, str(TOOLS_DIR))

import pytest


@pytest.fixture
def repo_dir() -> pathlib.Path:
    assert REPO_DIR.exists(), f"缺少 repo 快照: {REPO_DIR}（先运行 Task 3）"
    return REPO_DIR
