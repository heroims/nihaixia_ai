from parsers.acupoints import parse_acupoints


def test_parse_acupoints(repo_dir):
    md = (repo_dir / "modules" / "09_zhenjiu_bencao.md").read_text(encoding="utf-8", errors="ignore")
    pts = parse_acupoints(md)
    assert len(pts) > 50
    assert all(not p.name.isspace() for p in pts)