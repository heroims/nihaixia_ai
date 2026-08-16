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