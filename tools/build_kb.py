#!/usr/bin/env python3
"""把 nihaixia repo markdown 构建成 app 用的 kb.sqlite3。

用法:
  python tools/build_kb.py --repo tools/data/nihaixia --out tools/out
"""
from __future__ import annotations
import argparse
import pathlib
import sqlite3

from parsers.formulas import parse_formula_block
from parsers.md_utils import split_sections
from parsers.herbs import parse_herbs
from parsers.tiaowen import parse_tiaowen
from parsers.cases import parse_cases
from parsers.acupoints import parse_acupoints
from parsers.chunker import chunk_markdown

# modules/*.md 文件名 -> 描述性 source 名（用于 raw_chunks）
_MODULE_SOURCES: dict[str, str] = {
    "01_shanghan_sun.md": "伤寒论·太阳病",
    "02_shanghan_other.md": "伤寒论·其他",
    "03_yian.md": "医案集",
    "04_jingui.md": "金匮要略",
    "05_huangdi_neijing.md": "黄帝内经",
    "06_liangdong.md": "梁冬对话",
    "07_bimen_hantang.md": "闭门课",
    "08_huangdi_detail.md": "内经讲义",
    "09_zhenjiu_bencao.md": "针灸本草",
    "10_fuyang_luntan.md": "扶阳论坛",
    "11_zhongjing_xinfa.md": "仲景心法",
    "12_stanford_jingfang.md": "斯坦福经方",
    "13_shanghan_quebing.md": "伤寒论·缺篇",
    "14_yijinjing_bidu.md": "易筋经必读",
}

# 条文来源：伤寒论·太阳病 / 金匮要略 / 伤寒论·缺篇
_TIAOWEN_SOURCES: list[tuple[str, str]] = [
    ("伤寒论·太阳病", "modules/01_shanghan_sun.md"),
    ("金匮要略", "modules/04_jingui.md"),
    ("伤寒论·缺篇", "modules/13_shanghan_quebing.md"),
]

# 医案来源
_CASE_SOURCES: list[tuple[str, str]] = [
    ("癌症", "cases/01_cancer.md"),
    ("心血管", "cases/02_cardiovascular.md"),
    ("代谢", "cases/03_metabolic.md"),
    ("自身免疫", "cases/04_autoimmune.md"),
    ("神经精神", "cases/05_neurological.md"),
    ("其他", "cases/06_other.md"),
]

# cases 里非医案的 ### 区块标题关键词（核心要点提炼/上中下经/针刺要点/口吻参考/辨证要点）
_CASE_SKIP_KEYWORDS = ("要点", "上经", "下经", "中经", "口吻")


def build_database(output_dir: pathlib.Path, repo_dir: pathlib.Path) -> pathlib.Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    db_path = output_dir / "kb.sqlite3"
    if db_path.exists():
        db_path.unlink()

    con = sqlite3.connect(str(db_path))
    con.executescript("""
        PRAGMA journal_mode=OFF;
        CREATE TABLE herbs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL, taste TEXT, category TEXT,
          indications TEXT, dosage TEXT, taboo TEXT, raw TEXT,
          original TEXT, rongchuan TEXT, ni_zhu TEXT);
        CREATE TABLE formulas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT, title TEXT, key_symptoms TEXT,
          representative_mode TEXT, source_ref TEXT);
        CREATE TABLE tiao_wen(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          number TEXT, title TEXT, body TEXT, formula_hint TEXT, source TEXT);
        CREATE INDEX idx_tiaowen_source ON tiao_wen(source);
        CREATE TABLE cases(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT, body TEXT, symptoms TEXT, formula TEXT,
          category TEXT, source TEXT);
        CREATE TABLE acupoints(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT, meridian TEXT, location TEXT, indications TEXT, body TEXT);
        CREATE TABLE raw_chunks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          source TEXT, heading TEXT, text TEXT);
    """)

    # 1. herbs
    herb_md = (repo_dir / "modules" / "09_zhenjiu_bencao.md").read_text(encoding="utf-8", errors="ignore")
    for h in parse_herbs(herb_md):
        con.execute(
            "INSERT INTO herbs(name,taste,category,indications,dosage,taboo,raw,original,rongchuan,ni_zhu)"
            " VALUES(?,?,?,?,?,?,?,?,?,?)",
            (h.name, h.taste, h.category, h.indications, h.dosage, h.taboo,
             h.raw, h.original, h.rongchuan, h.ni_zhu))

    # 2. formulas —— 从 distilled 公式文件
    fm_md = (repo_dir / "references" / "distilled" / "01-six-meridian-formulas.md").read_text(encoding="utf-8", errors="ignore")
    for sec in split_sections(fm_md):
        if "诊断公式" not in sec.title:
            continue
        f = parse_formula_block(sec.body, title=sec.title)
        con.execute("INSERT INTO formulas(name,title,key_symptoms,representative_mode,source_ref) VALUES(?,?,?,?,?)",
                    (f.name, sec.title, f.key_symptoms, f.representative_mode, f.source_ref))

    # 3. tiao_wen
    for src, path_s in _TIAOWEN_SOURCES:
        p = repo_dir / path_s
        if not p.exists():
            continue
        md = p.read_text(encoding="utf-8", errors="ignore")
        for tw in parse_tiaowen(md, source=src):
            con.execute("INSERT INTO tiao_wen(number,title,body,formula_hint,source) VALUES(?,?,?,?,?)",
                        (tw.number, tw.title, tw.body, tw.formula_hint, tw.source))

    # 4. cases —— 过滤非医案区块；symptoms/formula 一并落库
    for cat, path_s in _CASE_SOURCES:
        p = repo_dir / path_s
        if not p.exists():
            continue
        md = p.read_text(encoding="utf-8", errors="ignore")
        for c in parse_cases(md, category=cat):
            if any(k in c.title for k in _CASE_SKIP_KEYWORDS):
                continue
            con.execute("INSERT INTO cases(title,body,symptoms,formula,category,source) VALUES(?,?,?,?,?,?)",
                        (c.title, c.body, c.symptoms, c.formula, c.category, c.source))

    # 5. acupoints
    for p in parse_acupoints(herb_md):
        con.execute("INSERT INTO acupoints(name,meridian,location,indications,body) VALUES(?,?,?,?,?)",
                    (p.name, p.meridian, p.location, p.indications, p.body))

    # 6. raw_chunks —— 全部 module + distilled + SKILL 段落
    chunk_sources: list[tuple[str, str]] = []
    modules_dir = repo_dir / "modules"
    if modules_dir.is_dir():
        for md_file in sorted(modules_dir.iterdir()):
            if md_file.suffix != ".md":
                continue
            src = _MODULE_SOURCES.get(md_file.name, md_file.stem)
            chunk_sources.append((src, f"modules/{md_file.name}"))
    for path_s in ("SKILL.md",):
        if (repo_dir / path_s).exists():
            chunk_sources.append(("SKILL", path_s))
    for path_s in ("references/distilled/01-six-meridian-formulas.md",
                   "references/distilled/02-acupuncture-quick-ref.md",
                   "references/distilled/03-clinical-experience.md"):
        if (repo_dir / path_s).exists():
            chunk_sources.append((path_s.split("/")[-1], path_s))
    for src, path_s in chunk_sources:
        p = repo_dir / path_s
        if not p.exists():
            continue
        md = p.read_text(encoding="utf-8", errors="ignore")
        for c in chunk_markdown(md, source=src):
            con.execute("INSERT INTO raw_chunks(source,heading,text) VALUES(?,?,?)",
                        (c.source, c.heading, c.text))

    con.commit()
    con.close()
    return db_path


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    db = build_database(pathlib.Path(args.out), pathlib.Path(args.repo))
    print(f"OK -> {db}")


if __name__ == "__main__":
    main()