# tools/parsers/cases.py
"""医案解析：按 ### 标题切分病例文件。
"""
from __future__ import annotations
import dataclasses
import re
from .md_utils import split_sections


@dataclasses.dataclass
class CaseRecord:
    title: str = ""
    body: str = ""
    symptoms: str = ""
    formula: str = ""
    category: str = ""
    source: str = ""


# 症状类字段：直接 `字段：` 或 `**字段**：` 行
_SYMPTOM_FIELDS = "|".join(["症状", "主诉", "病史", "现病史", "现症", "证候", "表现"])
_FORMULA_FIELDS = "|".join(["处方", "方剂", "用方", "药方", "治则", "治法"])


def _first_value(text: str, fields: str) -> str:
    bold = re.compile(
        rf"^\s*[-*+]?\s*\*\*(?P<k>{fields})\*\*\s*[:：]\s*(?P<v>.+?)\s*$"
    )
    plain = re.compile(
        rf"^\s*[-*+]?\s*(?P<k>{fields})(?:[（(][^）)]*[)）])?\s*[:：]\s*(?P<v>.+?)\s*$"
    )
    for ln in text.splitlines():
        s = ln.strip()
        m = bold.match(s) or plain.match(s)
        if m and m.group("k") and m.group("v").strip():
            return m.group("v").strip()
    return ""


def parse_cases(md: str, category: str = "", source: str = "cases/") -> list[CaseRecord]:
    out: list[CaseRecord] = []
    for sec in split_sections(md, level=3):
        body = sec.body
        out.append(CaseRecord(
            title=sec.title,
            body=body,
            symptoms=_first_value(body, _SYMPTOM_FIELDS) or "",
            formula=_first_value(body, _FORMULA_FIELDS) or "",
            category=category,
            source=source,
        ))
    return out