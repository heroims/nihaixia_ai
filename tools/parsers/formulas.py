# tools/parsers/formulas.py
"""解析 references/distilled/01-six-meridian-formulas.md 的诊断公式。"""
from __future__ import annotations
import dataclasses
import re
from .md_utils import split_sections, split_code_blocks


@dataclasses.dataclass
class DiagnosisFormula:
    name: str          # 六经名，如 太阳病
    title: str         # 原 section 标题
    key_symptoms: str  # 辨证公式提取的关键症状
    representative_mode: str = ""   # 代表方剂方向 / 治法
    source_ref: str = ""

_SOURCE_REF = "references/distilled/01-six-meridian-formulas.md"
_NAME_FROM_TITLE_RE = re.compile(r"^#{0,2}\s*诊断公式.+?：\s*(.+?)\s*$")
_TIGANG_RE = re.compile(r"^>\s*\**「(.+?)[」]")
_NAME_FROM_TIGANG_RE = re.compile(r"[「](.+?)[」]")


def parse_formula_block(body: str) -> DiagnosisFormula:
    """从单个 formula section body 中尽量提取结构化字段。"""
    name = ""
    key_symptoms = ""
    representative_mode = ""
    title = ""
    lines = body.splitlines()
    for ln in lines:
        s = ln.strip()
        # 标题行：``诊断公式一：太阳病'' 或 ``## 诊断公式一：太阳病''，冒号后即病名。
        m = _NAME_FROM_TITLE_RE.match(s)
        if m and not title:
            title = s
            name = m.group(1).strip()
        # 提纲：保留原文串（含关键症状）。
        if _TIGANG_RE.match(s):
            key_symptoms = s
        if not name:
            t = _NAME_FROM_TIGANG_RE.search(s)
            if t:
                name = t.group(1)
    return DiagnosisFormula(
        name=name or "未命名",
        title=title,
        key_symptoms=key_symptoms,
        representative_mode=representative_mode,
        source_ref=_SOURCE_REF,
    )