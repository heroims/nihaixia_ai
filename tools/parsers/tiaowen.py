# tools/parsers/tiaowen.py
"""解析伤寒/金匮条文（01_shanghan_sun.md / 04_jingui.md）。

数据协议（实测）：
- 01_shanghan_sun.md：条文块为 ``#### 条文N：标题`` 四级标题（``###`` 是分组头）。
  解析时按 level=4 切分并过滤出标题以「条文」开头的块，得到 132 条。
- 04_jingui.md：无条文编号；``##`` 为篇名，``####`` 为原文/师曰/问曰/方剂头。
  解析时按 level=4 切分并保留全部块（宁多勿漏，供下游构建/检索使用）。
"""
from __future__ import annotations
import dataclasses
import re
from .md_utils import split_sections


@dataclasses.dataclass
class TiaoWen:
    number: str = ""        # 条文号，如 "2"（金匮无编号则为空）
    title: str = ""
    body: str = ""          # 释义/解读
    formula_hint: str = ""  # 提及的方剂名（可空）
    source: str = ""


_NUMBER_RE = re.compile(r"^条文(\d+)")
_QUOTED_FANG_RE = re.compile(r"[「『]([^」』]{2,8}(?:汤|丸|散|膏))[」』]")
_NAKED_FANG_RE = re.compile(r"[\u4e00-\u9fff]{2,8}(?:汤|丸|散|膏)")


def _formula_hint(title: str, body: str) -> str:
    """标题/正文中优先取带「」的方名，其次裸方名。取第一个。"""
    for text in (title, body):
        m = _QUOTED_FANG_RE.search(text)
        if m:
            return m.group(1)
    for text in (title, body):
        m = _NAKED_FANG_RE.search(text)
        if m:
            return m.group(0)
    return ""


def parse_tiaowen(md: str, source: str) -> list[TiaoWen]:
    out: list[TiaoWen] = []
    for sec in split_sections(md, level=4):
        title = sec.title
        # 伤寒有 ``#### 条文N`` 标记，过滤非条文块；金匮无标记则全部保留。
        if source.startswith("伤寒"):
            if not title.startswith("条文"):
                continue
        number = ""
        m = _NUMBER_RE.match(title)
        if m:
            number = m.group(1)
        out.append(TiaoWen(
            number=number,
            title=title,
            body=sec.body,
            formula_hint=_formula_hint(title, sec.body),
            source=source,
        ))
    return out