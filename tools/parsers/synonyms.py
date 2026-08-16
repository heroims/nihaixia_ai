# tools/parsers/synonyms.py
"""小规模手工同义词表。别名 -> 正名。"""
from __future__ import annotations

SYNONYMS: dict[str, str] = {
    "柴胡汤": "小柴胡汤",
    "大柴胡": "大柴胡汤",
    "桂枝方": "桂枝汤",
    "麻黄方": "麻黄汤",
    "葛根方": "葛根汤",
    "小青龙": "小青龙汤",
    "大青龙": "大青龙汤",
    "生附子": "生附子",
    "炮附子": "炮附子",
}


def canonical_form(name: str) -> str:
    return SYNONYMS.get(name.strip(), name.strip())