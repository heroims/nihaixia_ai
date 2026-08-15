from parsers.chunker import chunk_markdown


def test_chunk_keeps_headings(repo_dir):
    md = (repo_dir / "modules" / "05_huangdi_neijing.md").read_text(encoding="utf-8", errors="ignore")
    chunks = chunk_markdown(md, source="黄帝内经")
    assert len(chunks) > 5
    assert all(c.text.strip() for c in chunks)


def test_chunk_size_bound(repo_dir):
    md = (repo_dir / "SKILL.md").read_text(encoding="utf-8", errors="ignore")
    chunks = chunk_markdown(md, source="SKILL", max_chars=800)
    assert all(len(c.text) <= 820 for c in chunks)