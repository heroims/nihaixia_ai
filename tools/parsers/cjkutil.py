"""jieba 中文索引切分 + token 列拼接。"""
from __future__ import annotations

import jieba

_jieba_loaded = False


def _ensure_loaded() -> None:
    global _jieba_loaded
    if not _jieba_loaded:
        jieba.initialize()
        _jieba_loaded = True


def cut_for_index(text: str) -> str:
    """返回空格分隔的 token 串，供 FTS5 检索或 token 子串匹配。"""
    _ensure_loaded()
    parts = [w for w in jieba.cut(text) if w.strip()]
    return " ".join(parts)


def tokens_for_query(text: str) -> list[str]:
    """对用户查询切分，返回去空、去重且保序的 token 列表。

    查询侧（App 离线端）无 jieba，本函数供构建期验证测试
    与多词 AND 匹配（Task 14）使用。
    """
    _ensure_loaded()
    seen: list[str] = []
    for w in jieba.cut(text):
        w = w.strip()
        if w and w not in seen:
            seen.append(w)
    return seen