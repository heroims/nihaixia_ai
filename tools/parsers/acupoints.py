# tools/parsers/acupoints.py
"""穴位解析：从针灸教程 markdown 中提取穴位记录。

真实数据（09_zhenjiu_bencao.md）两种主要形态，全部按实测适配：
1. 前段针灸（### 任脉/督脉/手足经下）：`- **中极穴**：主治描述` 加粗列表行
2. 后段经脉逐穴补遗：`### 极泉（手少阴心经）` + 描述正文，穴位名取自 ### 标题
   （标题可含多个穴名，如 `### 颔厌、悬颅、悬厘、曲鬓（手足少阳、阳明之会）`）
"""
from __future__ import annotations
import dataclasses
import re
from .md_utils import split_sections


@dataclasses.dataclass
class Acupoint:
    name: str = ""
    meridian: str = ""
    location: str = ""
    indications: str = ""
    body: str = ""


# 顶层穴位章节（按标题前缀或经脉名命中）
_TOP_PREFIX = ("人纪·针灸教程", "针灸补遗", "倪师治症经验", "经脉逐穴补遗")
_MERIDIAN_RE = re.compile(r"^(手|足)(太阴|少阴|厥阴|太阳|阳明|少阳).{1,2}经$")

# 段落式列表（`- **X穴**：主治`）出现且可信的 ### 小节标题
_BULLET_SECTIONS = {"任脉要穴", "督脉要穴", "手太阴肺经", "手阳明大肠经", "足阳明胃经"}

# 加粗列表行：`- **中极穴**：主治`
_BULLET_RE = re.compile(r"^\s*[-*+]\s*\*\*(.+?)\*\*\s*[：:]\s*(.*)$")
_H3_RE = re.compile(r"^###\s+(.+?)\s*$", re.M)

# 段落标题分割符
_NAME_SEP_RE = re.compile(r"[、，,/\s]+")

# 明显非穴位标题（跳过整段）
_SKIP_HEADING_SUB = ("治症", "全解", "三分法", "时间选穴", "详解", "待补")
# 无括号却会误判的段落标题（名称本身即非穴位）
_SKIP_HEADING_WORD = {"井荣俞经合"}

# 穴位名结尾后缀清理（顺序敏感）
_DROP_SUFFIX_RE = re.compile(r"穴$|穴详解$|详解$")


def _is_acup_section(title: str) -> bool:
    if title.startswith(_TOP_PREFIX):
        return True
    return bool(_MERIDIAN_RE.match(title))


def _clean_paren(md: str) -> str:
    """移除字符串内 `（...）` 括号块。"""
    return re.sub(r"（[^（）]*）", "", md)


def _parse_heading(title: str):
    """解析 `### 穴位名（经名·特征）` 标题。

    返回 (names: list[str], meridian: str) 或 (None, "")。
    """
    if any(s in title for s in _SKIP_HEADING_SUB):
        return None, ""
    match = re.findall(r"[（(]([^（()）]*)[)）]", title)
    base = _clean_paren(title).strip()
    paren = match[-1].strip() if match else ""
    base = _clean_paren(base).strip()
    base = base.replace("奇穴：", "")
    if not base or len(base) > 24:
        return None, ""
    names = []
    for raw in _NAME_SEP_RE.split(base):
        name = re.sub(r"[^\u4e00-\u9fff]+$", "", raw.strip())
        name = _DROP_SUFFIX_RE.sub("", name).strip()
        if not name or not re.search(r"[\u4e00-\u9fff]", name):
            continue
        if len(name) > 5 or name in _SKIP_HEADING_WORD:
            continue
        if name.endswith(("歌", "法", "经", "要", "要穴", "精选")):
            continue
        names.append(name)
    if not names:
        return None, ""
    meridian = ""
    if paren:
        token = re.split(r"[·、，；（）/]", paren)[0].strip()
        if token in ("经外奇穴", "奇穴", "奇穴组合"):
            meridian = token
        elif "经" in token:
            meridian = token
    return names, meridian


def _field(body: str, key: str) -> str:
    """从正文抽取 `定位：xxx` / `主治：xxx` 首行。"""
    m = re.search(rf"^\s*{key}[：:]\s*(.+?)\s*$", body, re.M)
    if m:
        return m.group(1).strip()
    m = re.search(rf"^\s*[-*+]\s*\*\*{key}\*\*[：:]\s*(.+?)\s*$", body, re.M)
    if m:
        return m.group(1).strip()
    return ""


def _bullet_meridian(h3_title: str) -> str:
    if h3_title.startswith("任脉"):
        return "任脉"
    if h3_title.startswith("督脉"):
        return "督脉"
    return ""


def _clean_bullet_name(raw: str) -> str:
    name = _DROP_SUFFIX_RE.sub("", raw.strip()).strip()
    if not re.search(r"[\u4e00-\u9fff]", name):
        return ""
    if not (1 <= len(name) <= 5) or name in _SKIP_HEADING_WORD:
        return ""
    if name.endswith(("歌", "法", "经", "要穴", "精选")):
        return ""
    return name


def parse_acupoints(md: str) -> list[Acupoint]:
    out: list[Acupoint] = []
    for sec in split_sections(md):
        if not _is_acup_section(sec.title):
            continue
        subs = split_sections(sec.body, level=3)
        # 顶段无 ### 的正文（如来源说明）一般无穴位行，忽略
        for sub in subs:
            names, meridian = _parse_heading(sub.title)
            if names:
                loc = _field(sub.body, "定位")
                ind = _field(sub.body, "主治") or ""
                for name in names:
                    out.append(Acupoint(
                        name=name, meridian=meridian,
                        location=loc, indications=ind,
                        body=sub.body,
                    ))
            else:
                # 白名单 ### 小节（任脉要穴/督脉要穴/经脉总述）：正文含 `- **X穴**：` 列表
                if sub.title not in _BULLET_SECTIONS:
                    continue
                bm = _bullet_meridian(sub.title)
                for ln in sub.body.splitlines():
                    m = _BULLET_RE.match(ln.strip())
                    if not m:
                        continue
                    name = _clean_bullet_name(m.group(1))
                    if not name:
                        continue
                    rest = m.group(2).strip()
                    out.append(Acupoint(
                        name=name, meridian=bm,
                        location="", indications=rest[:200],
                        body=rest,
                    ))
    return out