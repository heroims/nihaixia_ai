# tools/parsers/herbs.py
"""解析 09_zhenjiu_bencao.md 的本草（神农本草经）条目。

数据协议：本草段从 ``### 上经（137种）`` 起到 ``### 倪师口吻参考`` 前结束。
每个条目以单独成行的 ``**药名**`` 开标记，到下一个 ``**药名**`` 行结束；
条目内字段为 ``- 字段名：内容`` 无序列表行（字段顺序不固定，允许缺失/重复）。
字段包括：原文、性味、主治、用量、禁忌、倪注、容川 等。
品级（category）不在条目内，从外层 ``### 上经/中经/下经`` 标题继承。
"""
from __future__ import annotations
import dataclasses
import re

_ENTRY_RE = re.compile(r"^\*\*(.+?)\*\*\s*$")
_CATEGORY_RE = re.compile(r"^###\s*(上经|中经|下经)")
_FIELD_RE = re.compile(r"^-\s*([^：]+)：(.*)$")
_SUB_BLOCK_BAD = ("倪师临床口述", "视频讲义")


@dataclasses.dataclass
class Herb:
    name: str
    taste: str = ""       # 性味
    category: str = ""    # 上经/中经/下经
    indications: str = ""  # 主治
    dosage: str = ""
    taboo: str = ""
    raw: str = ""
    original: str = ""    # 原文
    rongchuan: str = ""   # 容川
    ni_zhu: str = ""      # 倪注


def parse_herbs(md: str) -> list[Herb]:
    herbs: list[Herb] = []
    current: Herb | None = None
    category = ""
    started = False
    for ln in md.splitlines():
        s = ln.strip()
        # 标题行：进入本草区 / 切换品级 / 离开本草区。
        if s.startswith("### "):
            m = _CATEGORY_RE.match(s)
            if m:
                started = True
                category = m.group(1)
            elif started:
                break
        if not started:
            continue
        # 条目开始标记：``**药名**`` 单独成行。
        m = _ENTRY_RE.match(s)
        if m and not any(bad in s for bad in _SUB_BLOCK_BAD):
            if current is not None:
                herbs.append(current)
            current = Herb(name=m.group(1).strip(), category=category, raw=s + "\n")
            continue
        # 条目内字段行／子块行，归到当前条目。
        if current is not None:
            current.raw += ln + "\n"
            fm = _FIELD_RE.match(s)
            if fm:
                field, val = fm.group(1).strip(), fm.group(2).strip()
                if field == "性味":
                    current.taste = val
                elif field == "主治":
                    current.indications = val
                elif field == "用量":
                    current.dosage = val
                elif field == "禁忌":
                    current.taboo = val
                elif field == "原文":
                    current.original = val
                elif field == "容川":
                    current.rongchuan = val
                elif field == "倪注":
                    current.ni_zhu = val
    if current is not None:
        herbs.append(current)
    # 去重保序。
    seen: set[str] = set()
    unique: list[Herb] = []
    for h in herbs:
        if h.name not in seen:
            seen.add(h.name)
            unique.append(h)
    return unique