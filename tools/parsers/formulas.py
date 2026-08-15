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
_BOLD_RE = re.compile(r"\*+([^*]+)\*+")


def _find_representative_mode(body: str) -> str:
    """找表头含「代表方」的第一个表格，取首行数据行最后一列（代表方剂方向）。"""
    rows: list[list[str]] = []
    for ln in body.splitlines():
        s = ln.strip()
        if s.startswith("|") and s.endswith("|"):
            cells = [_BOLD_RE.sub(r"\1", c.strip()) for c in s.strip("|").split("|")]
            if all(re.fullmatch(r":?-{2,}:?", c) for c in cells):  # 分隔行
                continue
            rows.append(cells)
        elif rows:
            if len(rows) >= 2 and "代表方" in rows[0]:
                return rows[1][-1].strip()
            rows = []
    if len(rows) >= 2 and "代表方" in rows[0]:
        return rows[1][-1].strip()
    return ""


def parse_formula_block(body: str, title: str = "") -> DiagnosisFormula:
    """从单个 formula section 中尽量提取结构化字段。

    title 由外部切分结果传入（如 ``诊断公式一：太阳病''）；为空时保留旧行为，
    在 body 内搜索 ``## 诊断公式'' 标题行，或以提纲句兜底。
    """
    name = ""
    key_symptoms = ""
    title_field = title
    if title.startswith("诊断公式") and "：" in title:
        name = title.split("：", 1)[1].strip()
    for ln in body.splitlines():
        s = ln.strip()
        # 标题行兜底：``## 诊断公式一：太阳病''（未传入 title 参数时）。
        m = _NAME_FROM_TITLE_RE.match(s)
        if m and not title_field:
            title_field = s
            if not name:
                name = m.group(1).strip()
        # 提纲：保留原文串（含关键症状）。
        if _TIGANG_RE.match(s):
            key_symptoms = s
        if not name:
            t = _NAME_FROM_TIGANG_RE.search(s)
            if t:
                name = t.group(1)
    representative_mode = _find_representative_mode(split_code_blocks(body))
    return DiagnosisFormula(
        name=name or "未命名",
        title=title_field,
        key_symptoms=key_symptoms,
        representative_mode=representative_mode,
        source_ref=_SOURCE_REF,
    )