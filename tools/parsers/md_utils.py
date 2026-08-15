# tools/parsers/md_utils.py
"""通用 markdown 解析辅助函数。"""
from __future__ import annotations
import dataclasses
import re


@dataclasses.dataclass
class Section:
    title: str
    body: str

_CODE_FENCE_RE = re.compile(r"```[\s\S]*?```")


def split_sections(md: str, level: int = 2) -> list[Section]:
    """按指定级别标题切分（默认 ## 二级）。返回 body 部分（不含标题行）。"""
    pattern = re.compile(rf"^\s*#{{{level}}}\s+(.+?)\s*$", re.M)
    matches = list(pattern.finditer(md))
    out: list[Section] = []
    for i, m in enumerate(matches):
        title = m.group(1).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(md)
        out.append(Section(title=title, body=md[start:end].strip()))
    return out


def extract_first_table(md: str) -> list[list[str]]:
    """抽取第一个 markdown 表格，返回行列表（首行为表头）。"""
    lines = md.splitlines()
    rows: list[list[str]] = []
    in_table = False
    for ln in lines:
        s = ln.strip()
        if s.startswith("|") and s.endswith("|"):
            if not in_table:
                in_table = True
            cells = [c.strip() for c in s.strip("|").split("|")]
            if all(re.fullmatch(r":?-{2,}:?", c) for c in cells):  # 分隔行
                continue
            rows.append(cells)
        elif in_table:
            break
    return rows


def split_code_blocks(md: str) -> str:
    """移除 ``` 代码块及 IF/THEN 规则串（ASCII 图形/规则字符串），保留其余文本。"""
    clean = _CODE_FENCE_RE.sub("", md)
    keep = [
        ln for ln in clean.splitlines()
        if not re.match(r"^\s*(IF|THEN)\b", ln.strip())
    ]
    return "\n".join(keep)