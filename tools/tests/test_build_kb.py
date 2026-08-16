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


def test_raw_chunks_retrievable(tmp_path, repo_dir):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=repo_dir)
    con = sqlite3.connect(db)
    n = con.execute("SELECT COUNT(*) FROM raw_chunks WHERE text IS NOT NULL AND text != ''").fetchone()[0]
    assert n > 0
    con.close()


def test_text_like_recall(tmp_path, repo_dir):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=repo_dir)
    con = sqlite3.connect(db)
    n = con.execute("SELECT COUNT(*) FROM raw_chunks WHERE text LIKE '%桂枝%'").fetchone()[0]
    assert n >= 500
    con.close()


def test_text_like_multiword_and(tmp_path, repo_dir):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=repo_dir)
    con = sqlite3.connect(db)
    n = con.execute("SELECT COUNT(*) FROM raw_chunks WHERE text LIKE '%怕冷%' AND text LIKE '%无汗%'").fetchone()[0]
    assert n >= 1
    con.close()


def test_raw_chunks_structure(tmp_path, repo_dir):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=repo_dir)
    con = sqlite3.connect(db)
    cols = [r[1] for r in con.execute("PRAGMA table_info(raw_chunks)")]
    assert cols == ["id", "source", "heading", "text"]
    con.close()


def test_no_chunks_fts(tmp_path, repo_dir):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=repo_dir)
    con = sqlite3.connect(db)
    row = con.execute("SELECT name FROM sqlite_master WHERE name='chunks_fts'").fetchone()
    assert row is None
    con.close()
