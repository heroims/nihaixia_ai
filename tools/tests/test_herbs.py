# tools/tests/test_herbs.py
from parsers.herbs import parse_herbs


def test_parse_herbs_on_real_module(repo_dir):
    md = (repo_dir / "modules" / "09_zhenjiu_bencao.md").read_text(encoding="utf-8", errors="ignore")
    herbs = parse_herbs(md)
    assert len(herbs) > 200, f"期望 200+ 味药，实际 {len(herbs)}"
    one = herbs[0]
    assert one.name
    assert any(field for field in (one.taste, one.category, one.indications))


def test_parse_herbs_tolerates_missing_fields():
    herbs = parse_herbs("## 无表格文本")
    assert herbs == []
