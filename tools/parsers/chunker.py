# tools/parsers/chunker.py
"""通用 markdown 段落 chunker：按标题切块，超长块在换行处切分。"""
from __future__ import annotations
import dataclasses
from .md_utils import Section, split_sections


@dataclasses.dataclass
class Chunk:
    source: str
    heading: str
    text: str


def _best_sections(md: str) -> list[Section]:
    """由高到低尝试标题级别，取首个段落数 >5 的级别；若皆不足则取最细分级。"""
    best: list[Section] | None = None
    for level in (2, 3, 4):
        secs = split_sections(md, level=level)
        if secs:
            best = secs
        if len(secs) > 5:
            return secs
    if best is None:
        best = [Section(title="", body=md)]
    return best


def chunk_markdown(md: str, source: str, max_chars: int = 800) -> list[Chunk]:
    chunks: list[Chunk] = []
    for sec in _best_sections(md):
        text = sec.body.strip()
        if not text:
            continue
        while len(text) > max_chars:
            cut = text[:max_chars]
            # 在最近换行处切断，避免句子被截断
            idx = cut.rfind("\n")
            idx = idx if idx > max_chars // 2 else max_chars
            chunks.append(Chunk(source=source, heading=sec.title, text=cut[:idx].strip()))
            text = text[idx:].strip()
        if text:
            chunks.append(Chunk(source=source, heading=sec.title, text=text))
    return chunks