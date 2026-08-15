# tools/tests/test_tiaowen.py
from parsers.tiaowen import parse_tiaowen


def test_parse_shanghan(repo_dir):
    md = (repo_dir / "modules" / "01_shanghan_sun.md").read_text(encoding="utf-8", errors="ignore")
    items = parse_tiaowen(md, source="伤寒论·太阳病")
    assert len(items) > 50
    assert items[0].number or items[0].title


def test_parse_jingui(repo_dir):
    md = (repo_dir / "modules" / "04_jingui.md").read_text(encoding="utf-8", errors="ignore")
    items = parse_tiaowen(md, source="金匮要略")
    assert len(items) > 5
