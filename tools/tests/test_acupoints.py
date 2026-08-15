from parsers.acupoints import parse_acupoints


def _real_points(repo_dir):
    md = (repo_dir / "modules" / "09_zhenjiu_bencao.md").read_text(encoding="utf-8", errors="ignore")
    return parse_acupoints(md)


def test_parse_acupoints(repo_dir):
    md = (repo_dir / "modules" / "09_zhenjiu_bencao.md").read_text(encoding="utf-8", errors="ignore")
    pts = parse_acupoints(md)
    assert len(pts) > 50
    assert all(not p.name.isspace() for p in pts)


def test_known_points(repo_dir):
    pts = _real_points(repo_dir)
    assert any(p.name == "中极" and p.meridian == "任脉" for p in pts)
    assert any(p.name == "合谷" for p in pts)


def test_overview_heading_not_parsed(repo_dir):
    pts = _real_points(repo_dir)
    assert not any("总览" in p.name for p in pts)