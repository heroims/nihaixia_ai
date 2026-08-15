# tools/tests/test_cases.py
from parsers.cases import parse_cases


def test_parse_case_files(repo_dir):
    md = (repo_dir / "cases" / "01_cancer.md").read_text(encoding="utf-8", errors="ignore")
    cases = parse_cases(md, category="癌症")
    assert len(cases) > 10


def test_parse_cases_tolerates_empty():
    assert parse_cases("", category="") == []