# tools/tests/test_build_kb.py
import sqlite3
from parsers.synonyms import canonical_form


def test_canonical_form_lookup():
    assert canonical_form("小柴胡汤") == "小柴胡汤"
    assert canonical_form("柴胡汤") == "小柴胡汤"
    assert canonical_form("炮附子") == "炮附子"


def test_build_creates_all_tables(tmp_path, repo_dir):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=repo_dir)
    con = sqlite3.connect(db)
    tables = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert {"herbs", "formulas", "tiao_wen", "cases", "acupoints", "raw_chunks"} <= tables
    con.execute("SELECT COUNT(*) FROM herbs").fetchone()
    con.close()


def test_fts5_virtual_table_created(tmp_path, repo_dir):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=repo_dir)
    con = sqlite3.connect(db)
    row = con.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='chunks_fts'").fetchone()
    assert row is not None
    con.close()


def test_raw_chunks_have_tokens(tmp_path, repo_dir):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=repo_dir)
    con = sqlite3.connect(db)
    n = con.execute("SELECT COUNT(*) FROM raw_chunks WHERE tokens IS NOT NULL AND tokens != ''").fetchone()[0]
    total = con.execute("SELECT COUNT(*) FROM raw_chunks").fetchone()[0]
    assert n == total
    con.close()


def test_chunks_fts_token_recall(tmp_path, repo_dir):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=repo_dir)
    con = sqlite3.connect(db)
    n = con.execute("SELECT COUNT(*) FROM raw_chunks WHERE tokens LIKE '%桂枝%'").fetchone()[0]
    assert n >= 100
    con.close()


def test_chunks_fts_multiword_and(tmp_path, repo_dir):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=repo_dir)
    con = sqlite3.connect(db)
    n = con.execute("SELECT COUNT(*) FROM raw_chunks WHERE tokens LIKE '%怕冷%' AND tokens LIKE '%无汗%'").fetchone()[0]
    assert n >= 1
    con.close()


def test_cjkutil_tokens(tmp_path):
    from parsers.cjkutil import cut_for_index, tokens_for_query
    assert "桂枝" in cut_for_index("桂枝汤主之")
    assert tokens_for_query("怕冷 没汗") == ["怕冷", "没汗"]
    assert tokens_for_query("怕冷，怕冷") == ["怕冷", "，"]