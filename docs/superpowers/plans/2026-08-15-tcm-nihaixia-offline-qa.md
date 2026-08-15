# 倪海厦中医离线问答 App 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用 Flutter 构建一款离线优先的倪海厦中医问答 App（知识库为 nihaixia repo），支持自由问答 + 引导式辨证双 Tab，分层可用（纯检索 → 端侧 LLM RAG → 可选云端增强）。

**Architecture:** 构建期 Python 工具把 repo markdown 解析为 SQLite 表 + FTS5 BM25 索引（随 App 打包）；App 内意图路由层分派到「规则引擎 / BM25 检索 / 端侧 LLM」三层；端侧 LLM（Qwen3 1.7B Q4，llama_cpp_dart）仅作 RAG 合成；云端层（OpenAI 兼容 API）默认关闭，解锁拍照看舌象与 Live 对话。

**Tech Stack:** Flutter + drift/sqflite + llama_cpp_dart；Python3 + jieba（构建工具）；SQLite FTS5；Qwen3-1.7B-Instruct Q4_K_M（~1.1GB）。

**参考 spec:** `docs/superpowers/specs/2026-08-14-tcm-nihaixia-offline-qa-design.md`

---

## 文件结构总览

```
yi/
├── docs/superpowers/plans/2026-08-15-tcm-nihaixia-offline-qa.md
├── tools/                          # 构建期 Python 工具（开发机运行）
│   ├── requirements.txt
│   ├── build_kb.py                 # 主入口：markdown → kb.sqlite3
│   ├── parsers/
│   │   ├── __init__.py
│   │   ├── formulas.py             # 诊断公式 → 结构化规则
│   │   ├── herbs.py                # 神农本草 345 种
│   │   ├── tiaowen.py              # 伤寒/金匮条文
│   │   ├── cases.py                # 医案
│   │   ├── acupoints.py            # 穴位
│   │   ├── chunker.py              # 通用段落 chunk
│   │   └── synonyms.py             # 同义词表
│   ├── tests/
│   │   ├── conftest.py
│   │   ├── test_formulas.py
│   │   ├── test_herbs.py
│   │   ├── test_tiaowen.py
│   │   ├── test_cases.py
│   │   ├── test_acupoints.py
│   │   ├── test_chunker.py
│   │   └── test_build_kb.py
│   └── data/nihaixia/              # repo 快照（git clone 产物）
├── app/                            # Flutter App
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/
│   │   │   ├── database.dart       # drift schema + DAO
│   │   │   └── models.dart         # 数据模型
│   │   ├── retrieval/
│   │   │   ├── intent_router.dart
│   │   │   ├── searcher.dart
│   │   │   ├── synonyms.dart
│   │   │   └── answer_assembler.dart
│   │   ├── rules/
│   │   │   └── diagnostic_engine.dart
│   │   ├── llm/
│   │   │   ├── llm_service.dart
│   │   │   ├── rag_synthesizer.dart
│   │   │   └── prompt_templates.dart
│   │   ├── cloud/
│   │   │   ├── cloud_config.dart
│   │   │   ├── cloud_client.dart
│   │   │   ├── photo_analyzer.dart
│   │   │   └── live_chat.dart
│   │   └── ui/
│   │       ├── home_page.dart
│   │       ├── qa_tab.dart
│   │       ├── diagnosis_tab.dart
│   │       ├── settings_tab.dart
│   │       └── widgets/
│   │           ├── disclaimer_banner.dart
│   │           ├── warning_card.dart
│   │           └── source_list.dart
│   ├── assets/
│   │   ├── kb/kb.sqlite3           # 构建产物（tools/build_kb.py 生成）
│   │   └── models/qwen3-1.7b-instruct-q4_k_m.gguf
│   └── test/
│       ├── retrieval_test.dart
│       ├── diagnostic_engine_test.dart
│       ├── rag_test.dart
│       └── cloud_test.dart
```

---

## M1：仓库初始化与工具脚手架

### Task 1: 初始化 git 仓库与目录骨架

**Files:**
- Create: `/Users/heroims/Desktop/yi/.gitignore`
- Create: `/Users/heroims/Desktop/yi/README.md`

- [ ] **Step 1: 创建 .gitignore**

写入 `tools/data/`（repo 快照不进 git）、`app/.dart_tool/`、`app/build/`、`*.gguf`、`__pycache__/`：

```gitignore
# python
__pycache__/
*.pyc
.venv/

# flutter
app/.dart_tool/
app/build/
app/.flutter-plugins
app/.flutter-plugins-dependencies
app/android/.gradle/

# 大文件，不入库
*.gguf
tools/data/nihaixia/
tools/out/
```

- [ ] **Step 2: 创建 README.md**

```markdown
# 倪海厦中医离线问答

离线优先的倪海厦经方中医问答 App。知识库来自 [nihaixia](https://github.com/jangviktor-web/nihaixia)（MulanPSL-2.0）。
详见 `docs/superpowers/specs/`。

## 项目结构
- `tools/` 构建期 Python 工具：markdown → SQLite
- `app/` Flutter 应用
```

- [ ] **Step 3: git init + 首次提交**

```bash
cd /Users/heroims/Desktop/yi
git init
git add .gitignore README.md docs/
git commit -m "chore: init repo with gitignore and docs"
```

Expected: commit 成功，不再跟踪大文件目录。

### Task 2: Python 构建工具骨架 + pytest

**Files:**
- Create: `/Users/heroims/Desktop/yi/tools/requirements.txt`
- Create: `/Users/heroims/Desktop/yi/tools/parsers/__init__.py`
- Create: `/Users/heroims/Desktop/yi/tools/tests/conftest.py`
- Create: `/Users/heroims/Desktop/yi/tools/tests/test_smoke.py`

- [ ] **Step 1: 写 requirements.txt**

```
jieba>=0.42.1
pytest>=7.0
```

- [ ] **Step 2: 建包与 conftest**

`parsers/__init__.py` 为空文件。`conftest.py` 提供 repo 快照路径 fixture（后续测试共用）：

```python
# tools/tests/conftest.py
import pathlib
import sys

TOOLS_DIR = pathlib.Path(__file__).resolve().parents[1]
REPO_DIR = TOOLS_DIR / "data" / "nihaixia"
sys.path.insert(0, str(TOOLS_DIR))

import pytest


@pytest.fixture
def repo_dir() -> pathlib.Path:
    assert REPO_DIR.exists(), f"缺少 repo 快照: {REPO_DIR}（先运行 Task 3）"
    return REPO_DIR
```

- [ ] **Step 3: 写冒烟测试**

```python
# tools/tests/test_smoke.py
def test_import_package():
    import parsers  # noqa: F401
    assert True
```

- [ ] **Step 4: 建 venv 并跑测试**

```bash
cd /Users/heroims/Desktop/yi/tools
python3 -m venv .venv
.venv/bin/pip install -q -r requirements.txt
.venv/bin/python -m pytest -q
```

Expected: `1 passed`。

- [ ] **Step 5: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add tools/
git commit -m "chore: scaffold python build tool with pytest"
```

### Task 3: 拉取 nihaixia repo 快照

**Files:**
- Create: `/Users/heroims/Desktop/yi/tools/data/nihaixia/`（git clone，不入库）

- [ ] **Step 1: 克隆 repo**

```bash
cd /Users/heroims/Desktop/yi/tools/data
git clone --depth 1 https://github.com/jangviktor-web/nihaixia.git
du -sh nihaixia
```

Expected: ~7.3MB。命令重跑（已存在则 `git -C nihaixia pull`）。

- [ ] **Step 2: 用 pytest fixture 验证快照可读**

```bash
cd /Users/heroims/Desktop/yi/tools
.venv/bin/python -c "
import pathlib
rd = pathlib.Path('data/nihaixia')
assert rd.exists()
files = [p for p in rd.rglob('*.md')]
print(f'{len(files)} 个 md 文件, 总大小 {sum(p.stat().st_size for p in files)/1e6:.1f}MB')
"
```

Expected: 输出约 30 个 md 文件、约 4MB。

---

## M2：构建期知识库解析（Python）

### Task 4: 通用 markdown 解析辅助 + 诊断公式解析

**Files:**
- Create: `/Users/heroims/Desktop/yi/tools/parsers/md_utils.py`
- Create: `/Users/heroims/Desktop/yi/tools/parsers/formulas.py`
- Test: `/Users/heroims/Desktop/yi/tools/tests/test_formulas.py`

- [ ] **Step 1: 写测试**

```python
# tools/tests/test_formulas.py
from parsers.md_utils import split_sections, extract_first_table, split_code_blocks
from parsers.formulas import parse_formula_block


def test_split_sections_splits_h2():
    md = "# 标题\n\n## 诊断公式一：太阳病\n\n内容A\n\n## 诊断公式二：阳明病\n\n内容B"
    secs = split_sections(md)
    assert [s.title for s in secs] == ["诊断公式一：太阳病", "诊断公式二：阳明病"]


def test_extract_first_table():
    md = "| 分型 | 治法 |\n|------|------|\n| 中风 | 解肌 |\n| 伤寒 | 发汗 |"
    rows = extract_first_table(md)
    assert rows[0] == ["分型", "治法"]
    assert rows[1] == ["中风", "解肌"]


def test_split_code_blocks_removes_ascii_diagrams():
    md = "## 标题\n\nIF\n```\n...图形...\n```\nTHEN 太阳病"
    clean = split_code_blocks(md)
    assert "```" not in clean and "IF" not in clean


def test_parse_formula_block_minimal():
    """fixture 数据中的公式块至少要能解析出名称字段。"""
    raw = (
        "## 诊断公式一：太阳病\n\n"
        "> 「太阳之为病，脉浮，头项强痛而恶寒。」\n\n"
        "### 辨证公式\n"
        "```\nIF 脉浮 + 头项强痛 + 恶寒\nTHEN → 太阳病\n```\n"
    )
    f = parse_formula_block(raw)
    assert f.name == "太阳病"
    assert "头项强痛" in f.key_symptoms
    assert f.source_ref  # 有出处
```

- [ ] **Step 2: 跑测试确认失败**

```bash
cd /Users/heroims/Desktop/yi/tools
.venv/bin/python -m pytest tests/test_formulas.py -v
```

Expected: FAIL（模块不存在）。

- [ ] **Step 3: 实现 md_utils.py**

```python
# tools/parsers/md_utils.py
"""通用 markdown 解析辅助函数。"""
from __future__ import annotations
import dataclasses
import re


@dataclasses.dataclass
class Section:
    title: str
    body: str

_H2_RE = re.compile(r"^\s*##\s+(.+?)\s*$", re.M)
_CODE_FENCE_RE = re.compile(r"```[\s\S]*?```")


def split_sections(md: str) -> list[Section]:
    """按 ## 二级标题切分。返回 body 部分（不含标题行）。"""
    matches = list(_H2_RE.finditer(md))
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
    """移除 ``` 代码块（ASCII 图形/规则字符串），保留其余文本。"""
    return _CODE_FENCE_RE.sub("", md)
```

- [ ] **Step 4: 实现 formulas.py**

```python
# tools/parsers/formulas.py
"""解析 references/distilled/01-six-meridian-formulas.md 的诊断公式。"""
from __future__ import annotations
import dataclasses
from .md_utils import split_sections, split_code_blocks


@dataclasses.dataclass
class DiagnosisFormula:
    name: str          # 六经名，如 太阳病
    title: str         # 原 section 标题
    key_symptoms: str  # 辨证公式提取的关键症状
    representative_mode: str = ""   # 代表方剂方向 / 治法
    source_ref: str = ""

_KEY_MATCHER = {
    "提纲": "提纲",
    "辨证公式": "公式",
}


def parse_formula_block(body: str) -> DiagnosisFormula:
    """从单个 formula section body 中尽量提取结构化字段。"""
    clean = split_code_blocks(body)
    name = ""
    key_symptoms = ""
    lines = clean.splitlines()
    for i, ln in enumerate(lines):
        s = ln.strip()
        # 名称：''诊断公式一：太阳病'' 作为 section title 已在外部传入，
        # 此函数接受 body，名称从内容里抓提纲句首。
        if s.startswith("> 「") and "之为病" in s:
            name = re_extract(s, r"[「](.+?)[」]")
            key_symptoms = s  # 保留提纲原文
        if "代表方" in s or "治法" in s or "方向" in s:
            representative_mode = s
    return DiagnosisFormula(
        name=name or "未命名",
        title="",
        key_symptoms=key_symptoms,
        source_ref="references/distilled/01-six-meridian-formulas.md",
    )


import re  # noqa: E402


def re_extract(text: str, pattern: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else ""
```

- [ ] **Step 5: 跑测试确认通过**

Run: `.venv/bin/python -m pytest tests/test_formulas.py -q`
Expected: `4 passed`。

- [ ] **Step 6: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add tools/parsers tools/tests
git commit -m "feat: parse diagnosis formulas from md"
```

### Task 5: 本草（神农本草经）解析

**Files:**
- Create: `/Users/heroims/Desktop/yi/tools/parsers/herbs.py`
- Test: `/Users/heroims/Desktop/yi/tools/tests/test_herbs.py`

- [ ] **Step 1: 写测试（先用真实 repo 部分行验证）**

```python
# tools/tests/test_herbs.py
from parsers.herbs import parse_herbs


def test_parse_herbs_on_real_module(repo_dir):
    md = (repo_dir / "modules" / "09_zhenjiu_bencao.md").read_text(encoding="utf-8", errors="ignore")
    herbs = parse_herbs(md)
    assert len(herbs) > 200, f"期望 200+ 味药，实际 {len(herbs)}"
    one = herbs[0]
    assert one.name
    assert any(field for field in (one.taste, one.category, one.indications))


def test_parse_herbs_tolerates_missing_fields():
    herbs = parse_herbs("## 无表格文本")
    assert herbs == []
```

- [ ] **Step 2: 跑测试确认失败**

Run: `.venv/bin/python -m pytest tests/test_herbs.py -v`
Expected: FAIL（模块不存在）。

- [ ] **Step 3: 实现 herbs.py（表格优先 + 标题兜底）**

```python
# tools/parsers/herbs.py
from __future__ import annotations
import dataclasses, re
from .md_utils import extract_first_table, split_sections


@dataclasses.dataclass
class Herb:
    name: str
    taste: str = ""       # 性味
    category: str = ""    # 上/中/下品
    indications: str = "" # 主治
    dosage: str = ""
    taboo: str = ""
    raw: str = ""


def parse_herbs(md: str) -> list[Herb]:
    herbs: list[Herb] = []
    for sec in split_sections(md):
        name = sec.title.strip()
        if not name or "针灸" in name or "本经" in name:
            continue
        rows = extract_first_table(sec.body)
        if not rows:
            continue
        header = rows[0]
        for row in rows[1:]:
            d = dict(zip(header, row + [""] * max(0, len(header) - len(row))))
            herbs.append(Herb(
                name=(d.get("名称") or d.get("药名") or name),
                taste=d.get("性味", ""),
                category=d.get("品", "") or d.get("三品", ""),
                indications=d.get("主治", ""),
                dosage=d.get("用量", ""),
                taboo=d.get("禁忌", ""),
                raw="\n".join(row),
            ))
    # 去重保序
    seen: set[str] = set()
    unique: list[Herb] = []
    for h in herbs:
        if h.name not in seen:
            seen.add(h.name)
            unique.append(h)
    return unique
```

- [ ] **Step 4: 跑测试确认通过**

Run: `.venv/bin/python -m pytest tests/test_herbs.py -q`
Expected: `2 passed`。若 parse 数 < 200 需先人工确认 repo 格式再调整。

- [ ] **Step 5: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add tools/parsers/herbs.py tools/tests/test_herbs.py
git commit -m "feat: parse herbs table"
```

### Task 6: 条文（伤寒/金匮）解析

**Files:**
- Create: `/Users/heroims/Desktop/yi/tools/parsers/tiaowen.py`
- Test: `/Users/heroims/Desktop/yi/tools/tests/test_tiaowen.py`

- [ ] **Step 1: 写测试**

```python
# tools/tests/test_tiaowen.py
from parsers.tiaowen import parse_tiaowen


def test_parse_shanghan(repo_dir):
    md = (repo_dir / "modules" / "01_shanghan_sun.md").read_text(encoding="utf-8", errors="ignore")
    items = parse_tiaowen(md, source="伤寒论·太阳病")
    assert len(items) > 50
    assert items[0].number or items[0].title


def test_parse_jingui(repo_dir):
    md = (repo_dir / "modules" / "04_jingui.md").read_text(encoding="utf-8", errors="ignore")
    items = parse_tiaowen(md, source="金匮要略")
    assert len(items) > 5
```

- [ ] **Step 2: 跑测试确认失败**

Run: `.venv/bin/python -m pytest tests/test_tiaowen.py -v`
Expected: FAIL。

- [ ] **Step 3: 实现 tiaowen.py**

```python
# tools/parsers/tiaowen.py
from __future__ import annotations
import dataclasses, re
from .md_utils import split_sections


@dataclasses.dataclass
class TiaoWen:
    number: str = ""      # 条文号，如 "1" / "太阳上篇"
    title: str = ""
    body: str = ""        # 释义/解读
    formula_hint: str = ""  # 提及的方剂名（可空）
    source: str = ""


def parse_tiaowen(md: str, source: str) -> list[TiaoWen]:
    out: list[TiaoWen] = []
    for sec in split_sections(md):
        number = ""
        title = sec.title
        m = re.match(r"^(?:第)?(\d+)(?:条)?", title)
        if m:
            number = m.group(1)
        body = sec.body
        fh = ""
        fm = re.search(r"[「『]([^」』]+汤[」』])|([\u4e00-\u9fff]{2,6}汤)", body)
        if fm:
            fh = fm.group(1) or fm.group(2)
        out.append(TiaoWen(number=number, title=title, body=body, formula_hint=fh, source=source))
    return out
```

- [ ] **Step 4: 跑测试确认通过**

Run: `.venv/bin/python -m pytest tests/test_tiaowen.py -q`
Expected: `2 passed`。

- [ ] **Step 5: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add tools/parsers/tiaowen.py tools/tests/test_tiaowen.py
git commit -m "feat: parse shanghan and jingui articles"
```

### Task 7: 医案解析

**Files:**
- Create: `/Users/heroims/Desktop/yi/tools/parsers/cases.py`
- Test: `/Users/heroims/Desktop/yi/tools/tests/test_cases.py`

- [ ] **Step 1: 写测试**

```python
# tools/tests/test_cases.py
from parsers.cases import parse_cases


def test_parse_case_files(repo_dir):
    md = (repo_dir / "cases" / "01_cancer.md").read_text(encoding="utf-8", errors="ignore")
    cases = parse_cases(md, category="癌症")
    assert len(cases) > 10


def test_parse_cases_tolerates_empty():
    assert parse_cases("", category="") == []
```

- [ ] **Step 2: 跑测试确认失败**

Run: `.venv/bin/python -m pytest tests/test_cases.py -v`
Expected: FAIL。

- [ ] **Step 3: 实现 cases.py**

```python
# tools/parsers/cases.py
from __future__ import annotations
import dataclasses
from .md_utils import split_sections


@dataclasses.dataclass
class CaseRecord:
    title: str = ""
    body: str = ""
    symptoms: str = ""
    formula: str = ""
    category: str = ""
    source: str = ""


def parse_cases(md: str, category: str = "", source: str = "cases/") -> list[CaseRecord]:
    out: list[CaseRecord] = []
    for sec in split_sections(md):
        body = sec.body
        out.append(CaseRecord(
            title=sec.title,
            body=body,
            category=category,
            source=source,
        ))
    return out
```

- [ ] **Step 4: 跑测试确认通过**

Run: `.venv/bin/python -m pytest tests/test_cases.py -q`
Expected: `2 passed`。

- [ ] **Step 5: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add tools/parsers/cases.py tools/tests/test_cases.py
git commit -m "feat: parse clinical cases"
```

### Task 8: 穴位解析 + 通用段落 chunker

**Files:**
- Create: `/Users/heroims/Desktop/yi/tools/parsers/acupoints.py`
- Create: `/Users/heroims/Desktop/yi/tools/parsers/chunker.py`
- Test: `/Users/heroims/Desktop/yi/tools/tests/test_acupoints.py`
- Test: `/Users/heroims/Desktop/yi/tools/tests/test_chunker.py`

- [ ] **Step 1: 写测试**

```python
# tools/tests/test_acupoints.py
from parsers.acupoints import parse_acupoints


def test_parse_acupoints(repo_dir):
    md = (repo_dir / "modules" / "09_zhenjiu_bencao.md").read_text(encoding="utf-8", errors="ignore")
    pts = parse_acupoints(md)
    assert len(pts) > 50
    assert all(not p.name.isspace() for p in pts)
```

```python
# tools/tests/test_chunker.py
from parsers.chunker import chunk_markdown


def test_chunk_keeps_headings(repo_dir):
    md = (repo_dir / "modules" / "05_huangdi_neijing.md").read_text(encoding="utf-8", errors="ignore")
    chunks = chunk_markdown(md, source="黄帝内经")
    assert len(chunks) > 5
    assert all(c.text.strip() for c in chunks)


def test_chunk_size_bound(repo_dir):
    md = (repo_dir / "SKILL.md").read_text(encoding="utf-8", errors="ignore")
    chunks = chunk_markdown(md, source="SKILL", max_chars=800)
    assert all(len(c.text) <= 820 for c in chunks)
```

- [ ] **Step 2: 跑测试确认失败**

Run: `.venv/bin/python -m pytest tests/test_acupoints.py tests/test_chunker.py -v`
Expected: FAIL（模块不存在）。

- [ ] **Step 3: 实现 acupoints.py**

```python
# tools/parsers/acupoints.py
from __future__ import annotations
import dataclasses
from .md_utils import split_sections


@dataclasses.dataclass
class Acupoint:
    name: str = ""
    meridian: str = ""
    location: str = ""
    indications: str = ""
    body: str = ""


_KNOWN_POINT_RE = (
    "中极|关元|石门|阴交|神阙|水分|下脘|中脘|上脘|鸠尾|膻中|天突|廉泉|承浆"
    "|合谷|太冲|足三里|内关|外关|后溪|风池|百会|曲池|阳陵泉|阴陵泉|三阴交|太溪|涌泉"
)


def parse_acupoints(md: str) -> list[Acupoint]:
    import re
    out: list[Acupoint] = []
    pattern = re.compile(rf"({_KNOWN_POINT_RE})穴?[：:、]?\s*(.*)")
    for sec in split_sections(md):
        for ln in sec.body.splitlines():
            m = pattern.match(ln.strip())
            if m:
                name = m.group(1)
                rest = m.group(2).strip()
                # 同一行可能含 ''穴名''多次，仅逐行首词名
                meridian = sec.title if len(sec.title) < 12 else ""
                out.append(Acupoint(name=name, meridian=meridian, body=rest, indications=rest[:200]))
    return out
```

- [ ] **Step 4: 实现 chunker.py**

```python
# tools/parsers/chunker.py
from __future__ import annotations
import dataclasses
from .md_utils import split_sections


@dataclasses.dataclass
class Chunk:
    source: str
    heading: str
    text: str


def chunk_markdown(md: str, source: str, max_chars: int = 800) -> list[Chunk]:
    chunks: list[Chunk] = []
    for sec in split_sections(md):
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
```

- [ ] **Step 5: 跑测试确认通过**

Run: `.venv/bin/python -m pytest tests/test_acupoints.py tests/test_chunker.py -q`
Expected: `4 passed`。

- [ ] **Step 6: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add tools/parsers/acupoints.py tools/parsers/chunker.py tools/tests/
git commit -m "feat: parse acupoints and raw chunking"
```

### Task 9: 同义词表 + 主构建脚本（产出 kb.sqlite3）

**Files:**
- Create: `/Users/heroims/Desktop/yi/tools/parsers/synonyms.py`
- Create: `/Users/heroims/Desktop/yi/tools/build_kb.py`
- Test: `/Users/heroims/Desktop/yi/tools/tests/test_build_kb.py`

- [ ] **Step 1: 写测试**

```python
# tools/tests/test_build_kb.py
import sqlite3, pathlib
from parsers.synonyms import canonical_form


def test_canonical_form_lookup():
    assert canonical_form("小柴胡汤") == "小柴胡汤"
    assert canonical_form("柴胡汤") == "小柴胡汤"
    assert canonical_form("炮附子") == "炮附子"


def test_build_creates_all_tables(tmp_path):
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=pathlib.Path("data/nihaixia"))
    con = sqlite3.connect(db)
    tables = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert {"herbs", "formulas", "tiao_wen", "cases", "acupoints", "raw_chunks"} <= tables
    con.execute("SELECT COUNT(*) FROM herbs").fetchone()
    con.close()


def test_fts5_virtual_table_created(tmp_path):
    import sqlite3, pathlib
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=pathlib.Path("data/nihaixia"))
    con = sqlite3.connect(db)
    row = con.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='chunks_fts'").fetchone()
    assert row is not None
    con.close()
```

- [ ] **Step 2: 跑测试确认失败**

Run: `.venv/bin/python -m pytest tests/test_build_kb.py -v`
Expected: FAIL（build_kb 不存在）。

- [ ] **Step 3: 实现 synonyms.py**

```python
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
    "s" : "s",  # 占位防误删；实际可删
}


def canonical_form(name: str) -> str:
    return SYNONYMS.get(name.strip(), name.strip())
```

- [ ] **Step 4: 实现 build_kb.py 主脚本**

```python
#!/usr/bin/env python3
"""把 nihaixia repo markdown 构建成 app 用的 kb.sqlite3。

用法:
  python tools/build_kb.py --repo tools/data/nihaixia --out tools/out
"""
from __future__ import annotations
import argparse
import dataclasses
import pathlib
import sqlite3

from parsers.formulas import parse_formula_block
from parsers.md_utils import split_sections, split_code_blocks
from parsers.herbs import parse_herbs
from parsers.tiaowen import parse_tiaowen
from parsers.cases import parse_cases
from parsers.acupoints import parse_acupoints
from parsers.chunker import chunk_markdown


def build_database(output_dir: pathlib.Path, repo_dir: pathlib.Path) -> pathlib.Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    db_path = output_dir / "kb.sqlite3"
    if db_path.exists():
        db_path.unlink()

    con = sqlite3.connect(str(db_path))
    con.executescript("""
        PRAGMA journal_mode=OFF;
        CREATE TABLE herbs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL, taste TEXT, category TEXT,
          indications TEXT, dosage TEXT, taboo TEXT, raw TEXT);
        CREATE TABLE formulas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT, title TEXT, key_symptoms TEXT,
          representative_mode TEXT, source_ref TEXT);
        CREATE TABLE tiao_wen(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          number TEXT, title TEXT, body TEXT, formula_hint TEXT, source TEXT);
        CREATE TABLE cases(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT, body TEXT, symptoms TEXT, formula TEXT,
          category TEXT, source TEXT);
        CREATE TABLE acupoints(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT, meridian TEXT, location TEXT, indications TEXT, body TEXT);
        CREATE TABLE raw_chunks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          source TEXT, heading TEXT, text TEXT);
    """)

    # 1. herbs
    herb_md = (repo_dir / "modules" / "09_zhenjiu_bencao.md").read_text(encoding="utf-8", errors="ignore")
    for h in parse_herbs(herb_md):
        con.execute("INSERT INTO herbs(name,taste,category,indications,dosage,taboo,raw) VALUES(?,?,?,?,?,?,?)",
                    (h.name, h.taste, h.category, h.indications, h.dosage, h.taboo, h.raw))

    # 2. formulas —— 从 distilled 公式文件
    fm_md = (repo_dir / "references" / "distilled" / "01-six-meridian-formulas.md").read_text(encoding="utf-8", errors="ignore")
    for sec in split_sections(fm_md):
        if "诊断公式" not in sec.title:
            continue
        f = parse_formula_block(sec.body)
        con.execute("INSERT INTO formulas(name,title,key_symptoms,representative_mode,source_ref) VALUES(?,?,?,?,?)",
                    (f.name, sec.title, f.key_symptoms, f.representative_mode, f.source_ref))

    # 3. tiao_wen
    for src, path_s in [("伤寒论·太阳病", "modules/01_shanghan_sun.md"),
                        ("伤寒论·其他", "modules/02_shanghan_other.md"),
                        ("金匮要略", "modules/04_jingui.md")]:
        md = (repo_dir / path_s).read_text(encoding="utf-8", errors="ignore")
        for tw in parse_tiaowen(md, source=src):
            con.execute("INSERT INTO tiao_wen(number,title,body,formula_hint,source) VALUES(?,?,?,?,?)",
                        (tw.number, tw.title, tw.body, tw.formula_hint, tw.source))

    # 4. cases
    for cat, path_s in [("癌症", "cases/01_cancer.md"), ("心血管", "cases/02_cardiovascular.md"),
                        ("代谢", "cases/03_metabolic.md"), ("自身免疫", "cases/04_autoimmune.md"),
                        ("神经精神", "cases/05_neurological.md"), ("其他", "cases/06_other.md")]:
        md = (repo_dir / path_s).read_text(encoding="utf-8", errors="ignore")
        for c in parse_cases(md, category=cat):
            con.execute("INSERT INTO cases(title,body,category,source) VALUES(?,?,?,?)",
                        (c.title, c.body, c.category, c.source))

    # 5. acupoints
    pts = parse_acupoints(herb_md)
    for p in pts:
        con.execute("INSERT INTO acupoints(name,meridian,location,indications,body) VALUES(?,?,?,?,?)",
                    (p.name, p.meridian, p.location, p.indications, p.body))

    # 6. raw_chunks —— 全部 module + distilled + SKILL 段落
    chunk_sources: list[tuple[str, str]] = [
        ("伤寒论·太阳", "modules/01_shanghan_sun.md"),
        ("伤寒论·其他", "modules/02_shanghan_other.md"),
        ("医案集", "modules/03_yian.md"),
        ("金匮要略", "modules/04_jingui.md"),
        ("黄帝内经", "modules/05_huangdi_neijing.md"),
        ("梁冬对话", "modules/06_liangdong.md"),
        ("闭门课", "modules/07_bimen_hantang.md"),
        ("内经讲义", "modules/08_huangdi_detail.md"),
        ("针灸本草", "modules/09_zhenjiu_bencao.md"),
        ("SKILL", "SKILL.md"),
        ("诊断速查", "references/distilled/01-six-meridian-formulas.md"),
        ("针灸速查", "references/distilled/02-acupuncture-quick-ref.md"),
        ("临床经验", "references/distilled/03-clinical-experience.md"),
    ]
    for src, path_s in chunk_sources:
        p = repo_dir / path_s
        if not p.exists():
            continue
        md = p.read_text(encoding="utf-8", errors="ignore")
        for c in chunk_markdown(md, source=src):
            con.execute("INSERT INTO raw_chunks(source,heading,text) VALUES(?,?,?)",
                        (c.source, c.heading, c.text))

    # 7. FTS5 BM25 索引（raw_chunks.text 剪枝后）
    con.executescript("""
        CREATE VIRTUAL TABLE chunks_fts USING fts5(
          text, content='raw_chunks', content_rowid='id', tokenize='unicode61');
        INSERT INTO chunks_fts(rowid, text)
          SELECT id, text FROM raw_chunks;
    """)

    con.commit()
    con.close()
    return db_path


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    db = build_database(pathlib.Path(args.out), pathlib.Path(args.repo))
    print(f"OK -> {db}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 5: 跑测试确认通过**

Run: `.venv/bin/python -m pytest tests/test_build_kb.py -q`
Expected: `3 passed`。

- [ ] **Step 6: 真实构建并人工检查**

```bash
cd /Users/heroims/Desktop/yi/tools
.venv/bin/python build_kb.py --repo data/nihaixia --out out
.venv/bin/python -c "
import sqlite3
c = sqlite3.connect('out/kb.sqlite3')
for t in ['herbs','formulas','tiao_wen','cases','acupoints','raw_chunks']:
    print(t, c.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0])
"
```

Expected: herbs~345、formulas~8、tiao_wen~120+、cases~200+、raw_chunks 数百。

- [ ] **Step 7: 提交**（产物 out/ 不入库，.gitignore 已加）

```bash
cd /Users/heroims/Desktop/yi
git add tools/build_kb.py tools/parsers/synonyms.py tools/tests/test_build_kb.py
git commit -m "feat: full kb build script with fts5 index"
```

### Task 10: 中文分词嵌入（jieba 预切分 token 列）

**Files:**
- Modify: `/Users/heroims/Desktop/yi/tools/build_kb.py`
- Test: `/Users/heroims/Desktop/yi/tools/tests/test_build_kb.py`

- [ ] **Step 1: 加 token 列测试**

```python
# tools/tests/test_build_kb.py 追加
def test_raw_chunks_have_tokens(tmp_path):
    import sqlite3, pathlib
    from build_kb import build_database
    db = build_database(output_dir=tmp_path, repo_dir=pathlib.Path("data/nihaixia"))
    con = sqlite3.connect(db)
    n = con.execute("SELECT COUNT(*) FROM raw_chunks WHERE tokens IS NOT NULL AND tokens != ''").fetchone()[0]
    total = con.execute("SELECT COUNT(*) FROM raw_chunks").fetchone()[0]
    assert n == total
    con.close()
```

- [ ] **Step 2: 跑测试确认失败**

Run: `.venv/bin/python -m pytest tests/test_build_kb.py::test_raw_chunks_have_tokens -v`
Expected: FAIL（no such column: tokens）。

- [ ] **Step 3: 实现 jieba 切分**

修改 `build_kb.py`：
- 顶部 import：`from parsers.cjkutil import cut_for_index`
- 新建 `tools/parsers/cjkutil.py`：

```python
# tools/parsers/cjkutil.py
"""jieba 中文索引切分 + token 列拼接。"""
from __future__ import annotations
import jieba

_jieba_loaded = False


def cut_for_index(text: str) -> str:
    """返回空格分隔的 token 串，供 FTS5 unindexed 检索或 token 匹配。"""
    global _jieba_loaded
    if not _jieba_loaded:
        jieba.initialize()
        _jieba_loaded = True
    parts = [w for w in jieba.cut(text) if w.strip()]
    return " ".join(parts)
```

- raw_chunks 表增加 `tokens TEXT` 列，insert 时 `cut_for_index(c.text)`：

```python
# build_kb.py 修改处
con.executescript("""
    CREATE TABLE raw_chunks(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      source TEXT, heading TEXT, text TEXT, tokens TEXT);
""")
# ...
for c in chunk_markdown(md, source=src):
    con.execute("INSERT INTO raw_chunks(source,heading,text,tokens) VALUES(?,?,?,?)",
                (c.source, c.heading, c.text, cut_for_index(c.text)))
```

- [ ] **Step 4: 跑测试确认通过**

Run: `.venv/bin/python -m pytest tests/test_build_kb.py -q`
Expected: `4 passed`。

- [ ] **Step 5: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add tools/build_kb.py tools/parsers/cjkutil.py tools/tests/test_build_kb.py
git commit -m "feat: jieba token column for retrieval"
```

---

## M3：Flutter 应用骨架 + 检索层

### Task 11: Flutter 项目初始化 + drift/llama 依赖

**Files:**
- Create: `/Users/heroims/Desktop/yi/app/pubspec.yaml`（flutter create 生成后修改）
- Create: `/Users/heroims/Desktop/yi/app/lib/main.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/app.dart`

- [ ] **Step 1: flutter create**

```bash
cd /Users/heroims/Desktop/yi
flutter create --platforms android,ios --org com.nihaixia --project-name nihaixia_app app
```

Expected: 生成 app/ 目录。若 android SDK 缺失，仅保证 lib/ 与测试可用（`flutter test --no-pub` 对齐）。

- [ ] **Step 2: 写 pubspec.yaml（合并依赖）**

```yaml
name: nihaixia_app
description: 倪海厦中医离线问答
publish_to: "none"
version: 0.1.0

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.2
  path: ^1.9.0
  shared_preferences: ^2.2.3
  http: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.16.0
  build_runner: ^2.4.8

flutter:
  assets:
    - assets/kb/kb.sqlite3
```

> 注：llama_cpp_dart 在 M5 引入（Task 17），此处先不加以免初始 pub get 卡住。tokens 检索阶段（M3/M4）不依赖它，检索走 drift/FTS5。

- [ ] **Step 3: 写最小可跑 main.dart + app.dart**

`lib/main.dart`：

```dart
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const NihaixiaApp());
}
```

`lib/app.dart`：

```dart
import 'package:flutter/material.dart';

class NihaixiaApp extends StatelessWidget {
  const NihaixiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '倪海厦中医问答',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomePage(),
    );
  }
}
```

先占位 `HomePage`（M4 实现），此处返回简单 Scaffold：

`lib/ui/home_page.dart`：

```dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('占位')));
  }
}
```

- [ ] **Step 4: pub get + 冒烟测试**

将 `app/test/widget_test.dart` 替换为可跑测试：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/app.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const NihaixiaApp());
    expect(find.text('占位'), findsOneWidget);
  });
}
```

```bash
cd /Users/heroims/Desktop/yi/app
flutter pub get
flutter test
```

Expected: `flutter test` 通过。

- [ ] **Step 5: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/
git commit -m "feat: scaffold flutter app with drift deps"
```

### Task 12: drift 数据模型（表 + DAO）

**Files:**
- Create: `/Users/heroims/Desktop/yi/app/lib/core/database.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/core/database.g.dart`（build_runner 生成）

- [ ] **Step 1: 写 database.dart**

```dart
import 'package:drift/drift.dart';

part 'database.g.dart';

class Herbs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get taste => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get indications => text().nullable()();
  TextColumn get dosage => text().nullable()();
  TextColumn get taboo => text().nullable()();
}

class Formulas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get keySymptoms => text().withDefault(const Constant(''))();
  TextColumn get representativeMode => text().withDefault(const Constant(''))();
  TextColumn get sourceRef => text().withDefault(const Constant(''))();
}

class TiaoWen extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get number => text().withDefault(const Constant(''))();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get formulaHint => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant(''))();
}

class Cases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get symptoms => text().withDefault(const Constant(''))();
  TextColumn get formula => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant(''))();
}

class Acupoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get meridian => text().withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get indications => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();
}

class RawChunks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get source => text().withDefault(const Constant(''))();
  TextColumn get heading => text().withDefault(const Constant(''))();
  TextColumn get text => text()();
  TextColumn get tokens => text().nullable()();
}

@DriftDatabase(tables: [Herbs, Formulas, TiaoWen, Cases, Acupoints, RawChunks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
```

- [ ] **Step 2: 生成 g.dart**

```bash
cd /Users/heroims/Desktop/yi/app
dart run build_runner build --delete-conflicting-outputs
```

Expected: 生成 `database.g.dart`。

- [ ] **Step 3: 跑现有测试确认没坏**

Run: `flutter test`
Expected: PASS。

- [ ] **Step 4: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/core/database.dart app/lib/core/database.g.dart
git commit -m "feat: drift database schema"
```

### Task 13: 检索层（意图路由 + FTS5 搜索 + 同义词）

**Files:**
- Create: `/Users/heroims/Desktop/yi/app/lib/retrieval/intent_router.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/retrieval/searcher.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/retrieval/synonyms.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/retrieval/answer_assembler.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/retrieval_test.dart`

- [ ] **Step 1: 写测试（纯逻辑，不依赖数据库）**

```dart
// app/test/retrieval_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/retrieval/intent_router.dart';
import 'package:nihaixia_app/retrieval/synonyms.dart';
import 'package:nihaixia_app/retrieval/answer_assembler.dart';

void main() {
  group('intent router', () {
    test('识别方剂查询', () {
      expect(IntentRouter.classify('小柴胡汤什么时候用'), Intent.herbFormula);
    });
    test('识别症状辨证', () {
      expect(IntentRouter.classify('我感冒了怕冷没汗'), Intent.diagnosis);
    });
    test('识别药物', () {
      expect(IntentRouter.classify('生附子和炮附子的区别'), Intent.herbFormula);
    });
    test('无法识别回退 general', () {
      expect(IntentRouter.classify('你好呀'), Intent.general);
    });
  });

  group('synonyms', () {
    test('别名归正', () {
      expect(Synonyms.canonicalize('柴胡汤'), '小柴胡汤');
    });
    test('无别名原样返回', () {
      expect(Synonyms.canonicalize('桂枝汤'), '桂枝汤');
    });
  });

  group('answer assembler', () {
    test('无证据时提示资料不足', () {
      const out = AnswerAssembler.formatEmpty();
      expect(out, contains('资料中未找到'));
    });
    test('有证据时拼接出处', () {
      const out = AnswerAssembler.formatSnippet(
        sources: ['伤寒论·第1条', '金匮·卒病'],
      );
      expect(out, contains('伤寒论'));
      expect(out, contains('（来源）'));
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/retrieval_test.dart`
Expected: FAIL（模块不存在）。

- [ ] **Step 3: 实现 intent_router.dart**

```dart
import 'package:nihaixia_app/retrieval/synonyms.dart';

enum Intent { diagnosis, herbFormula, general }

class IntentRouter {
  static const _diagKeywords = ['感冒', '怕冷', '没汗', '有汗', '发热', '恶寒',
    '恶风', '口渴', '睡眠', '大便', '小便', '舌象', '脉象'];

  static const _formulaKeywords = ['汤', '方', '怎么用', '剂量', '什么时候用',
    '附子', '黄芪', '人参', '当归', '桂枝', '麻黄', '芍药'];

  static Intent classify(String query) {
    final q = query.trim();
    if (q.isEmpty) return Intent.general;
    // 先做同义词归一后匹配方剂名特征
    final canonical = Synonyms.canonicalize(q);
    if (canonical.contains('汤') || _hasAny(_formulaKeywords, q)) {
      // 但「感冒」同时满足诊断关键词时，优先进诊断
      if (_hasAny(_diagKeywords, q) && !q.contains('汤')) {
        return Intent.diagnosis;
      }
      return Intent.herbFormula;
    }
    if (_hasAny(_diagKeywords, q)) return Intent.diagnosis;
    return Intent.general;
  }

  static bool _hasAny(List<String> kws, String text) =>
      kws.any((k) => text.contains(k));
}
```

- [ ] **Step 4: 实现 synonyms.dart**

```dart
class Synonyms {
  static const Map<String, String> _table = {
    '柴胡汤': '小柴胡汤',
    '大柴胡': '大柴胡汤',
    '桂枝方': '桂枝汤',
    '麻黄方': '麻黄汤',
    '葛根方': '葛根汤',
    '小青龙': '小青龙汤',
    '大青龙': '大青龙汤',
  };

  static String canonicalize(String text) {
    for (final entry in _table.entries) {
      if (text.contains(entry.key)) {
        return text.replaceAll(entry.key, entry.value);
      }
    }
    return text;
  }
}
```

- [ ] **Step 5: 实现 answer_assembler.dart**

```dart
class AnswerAssembler {
  static String formatEmpty() => '资料中未找到相关内容。';

  static String formatSnippet({
    required List<String> sources,
    String? answer,
  }) {
    final buf = StringBuffer();
    if (answer != null && answer.isNotEmpty) buf.write(answer);
    buf.writeln();
    buf.writeln();
    buf.writeln('（来源）');
    for (final s in sources.take(5)) {
      buf.writeln('· $s');
    }
    return buf.toString();
  }
}
```

- [ ] **Step 6: 跑测试确认通过**

Run: `cd app && flutter test test/retrieval_test.dart`
Expected: `8 passed`。

- [ ] **Step 7: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/retrieval/ app/test/retrieval_test.dart
git commit -m "feat: intent routing and retrieval logic"
```

### Task 14: searcher（FTS5 + drift DAO 查询）

**Files:**
- Create: `/Users/heroims/Desktop/yi/app/lib/retrieval/searcher.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/searcher_test.dart`

- [ ] **Step 1: 写测试（用内存 sqlite3 注入伪造数据）**

使用 `sqlite3` package 的内存数据库 + drift：

```dart
// app/test/searcher_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/retrieval/searcher.dart';
import 'package:nihaixia_app/core/models.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    // 插入最小 FTS 数据需走 raw_chunks + chunks_fts
  });

  tearDown(() => db.close());

  test('fts returns matching chunk', () async {
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
      source: '伤寒论',
      heading: '第1条',
      text: '太阳之为病，脉浮，头项强痛而恶寒。',
      tokens: const Value('太阳 之 为病 脉浮 头项 强痛 而 恶寒'),
    ));
    // 手工建 FTS 索引（真实 app 由 assets 导入）
    await db.customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(text, content='raw_chunks', content_rowid='id', tokenize='unicode61');
      INSERT INTO chunks_fts(rowid, text) SELECT 1, '太阳之为病，脉浮，头项强痛而恶寒。';
    ''');
    final res = await Searcher.searchByFts(db, '恶寒');
    expect(res, isNotEmpty);
    expect(res.first, contains('恶寒'));
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/searcher_test.dart`
Expected: FAIL（searcher 不存在 + FTS 表缺失需处理）。

- [ ] **Step 3: 实现 models.dart（检索结果模型）**

`app/lib/core/models.dart`：

```dart
class SearchHit {
  final String source;
  final String heading;
  final String text;
  const SearchHit({
    required this.source,
    required this.heading,
    required this.text,
  });
}
```

- [ ] **Step 4: 实现 searcher.dart**

```dart
import 'package:drift/drift.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/core/models.dart';

/// 若 assets 数据库未建 FTS 表，则迁移时补建。
Future<void> ensureFts(DatabaseConnectionUser db) async {
  await db.customStatement('''
    CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(
      text, content='raw_chunks', content_rowid='id', tokenize='unicode61');
  ''');
}

class Searcher {
  /// FTS5 全文检索；返回按相关性排序的 raw_chunks。
  /// query 需为空格分隔的词或短语；词组建议用双引号包裹。
  static Future<List<SearchHit>> searchByFts(
    DatabaseConnectionUser db,
    String query, {
    int limit = 8,
  }) async {
    await ensureFts(db);
    // 转义 FTS 特殊字符
    final esc = query.replaceAll('"', ' ').trim();
    if (esc.isEmpty) return const [];
    final rows = await db.customSelect(
      'SELECT rc.source, rc.heading, rc.text '
      'FROM chunks_fts JOIN raw_chunks rc ON rc.id = chunks_fts.rowid '
      'WHERE chunks_fts MATCH ? ORDER BY bm25(chunks_fts) LIMIT ?',
      variables: [
        Variable('"$esc"'),
        Variable(limit),
      ],
    ).get();
    return rows.map((r) => SearchHit(
      source: r.read<String>('source'),
      heading: r.read<String>('heading'),
      text: r.read<String>('text'),
    )).toList();
  }

  /// 精确查询方剂/药物名（走结构化表 LIKE 匹配）。
  static Future<List<SearchHit>> searchFei({
    required DatabaseConnectionUser db,
    required String table,
    required String keyword,
    int limit = 5,
  }) async {
    final where = 'name LIKE ?';
    final rows = await db.customSelect(
      'SELECT name, "${'\"+'"'
        .replaceAll('"', '');
      // 简化：直接 SQL 聚合
  }
}
```

> 注：`searchFei` 的精确查询在 Task 15 边界上改由 Model 层封装更清晰（见 Task 15 的 Herb/Fang 服务）。此处先保证 `searchByFts` 完整可测；`searchFei` 的具体结构化查询在 Task 15 用 drift 的 select/getSingle 重写，测试同步补齐。

- [ ] **Step 5: 跑测试确认通过**

Run: `cd app && flutter test test/searcher_test.dart`
Expected: PASS（searchByFts 用例）。

- [ ] **Step 6: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/retrieval/searcher.dart app/lib/core/models.dart app/test/searcher_test.dart
git commit -m "feat: fts5 full-text search via drift"
```

---

## M4：UI（Home 双 Tab） + 规则引擎

### Task 15: 结构化查询服务（Herb/Fang/Case 查询）

**Files:**
- Create: `/Users/heroims/Desktop/yi/app/lib/retrieval/structured_queries.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/structured_queries_test.dart`

- [ ] **Step 1: 写测试**

```dart
// app/test/structured_queries_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/retrieval/structured_queries.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('查 herbs 按名', () async {
    await db.into(db.herbs).insert(HerbsCompanion.insert(
      name: '桂枝',
      taste: const Value('辛温'),
      indications: const Value('解肌发表'),
    ));
    final rows = await StructuredQueries.findHerbs(db, '桂枝');
    expect(rows, isNotEmpty);
    expect(rows.first.name, '桂枝');
  });

  test('查 tiao_wen 含方剂', () async {
    await db.into(db.tiaoWen).insert(TiaoWenCompanion.insert(
      number: const Value('1'),
      title: const Value('太阳病提纲'),
      body: const Value('太阳之为病，脉浮，头项强痛而恶寒。'),
      formulaHint: const Value(''),
      source: const Value('伤寒论'),
    ));
    final rows = await StructuredQueries.findTiaoWen(db, '恶寒');
    expect(rows, isNotEmpty);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/structured_queries_test.dart`
Expected: FAIL（模块不存在）。

- [ ] **Step 3: 实现 structured_queries.dart**

```dart
import 'package:drift/drift.dart';
import 'package:nihaixia_app/core/database.dart';

class StructuredQueries {
  static Future<List<Herb>> findHerbs(Database db, String name) async {
    final like = '%$name%';
    return (db.select(db.herbs)..where((h) => h.name.like(like))..limit(10)).get();
  }

  static Future<List<TiaoWen>> findTiaoWen(Database db, String kw) async {
    final like = '%$kw%';
    return (db.select(db.tiaoWen)
          ..where((t) => t.body.like(like) | t.title.like(like))
          ..limit(10))
        .get();
  }

  static Future<List<Case>> findCases(Database db, String kw) async {
    final like = '%$kw%';
    return (db.select(db.cases)
          ..where((c) => c.title.like(like) | c.body.like(like))
          ..limit(10))
        .get();
  }
}
```

> 注：`Herb`/`TiaoWen`/`Case` 为 drift 生成的类名（`Herbs` 表 -> `Herb` row）。

- [ ] **Step 4: 跑测试确认通过**

Run: `cd app && flutter test test/structured_queries_test.dart`
Expected: `2 passed`。

- [ ] **Step 5: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/retrieval/structured_queries.dart app/test/structured_queries_test.dart
git commit -m "feat: structured queries for herbs and articles"
```

### Task 16: 引导诊断规则引擎

**Files:**
- Create: `/Users/heroims/Desktop/yi/app/lib/rules/diagnostic_engine.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/diagnostic_engine_test.dart`

- [ ] **Step 1: 写测试**

```dart
// app/test/diagnostic_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/rules/diagnostic_engine.dart';

void main() {
  group('太阳病规则', () {
    test('无汗恶寒体痛 → 太阳伤寒', () {
      final r = DiagnosticEngine.evaluate(SymptomInput(
        sweat: SweatState.noSweat,
        cold: ColdState.aversionToCold,
        painNeck: true,
      ));
      expect(r.jing, '太阳病');
      expect(r.suggestedFormula, contains('麻黄汤'));
    });

    test('有汗恶风 → 太阳中风', () {
      final r = DiagnosticEngine.evaluate(SymptomInput(
        sweat: SweatState.hasSweat,
        cold: ColdState.aversionToWind,
        painNeck: true,
      ));
      expect(r.jing, '太阳病');
      expect(r.suggestedFormula, contains('桂枝汤'));
    });
  });

  test('信息不足时提示需更多症状', () {
    final r = DiagnosticEngine.evaluate(const SymptomInput());
    expect(r.jing, isEmpty);
    expect(r.message, contains('需要更多症状'));
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/diagnostic_engine_test.dart`
Expected: FAIL（模块不存在）。

- [ ] **Step 3: 实现 diagnostic_engine.dart**

```dart
enum SweatState { unknown, hasSweat, noSweat }
enum ColdState { unknown, aversionToCold, aversionToWind, aversionToHeat }

class SymptomInput {
  final SweatState sweat;
  final ColdState cold;
  final bool painNeck;
  final bool bodyAche;
  final bool thirst;
  final bool fever;
  const SymptomInput({
    this.sweat = SweatState.unknown,
    this.cold = ColdState.unknown,
    this.painNeck = false,
    this.bodyAche = false,
    this.thirst = false,
    this.fever = false,
  });
}

class DiagnosisResult {
  final String jing;      // 六经名
  final String suggestedFormula; // 代表方方向
  final String message;   // 用户提示（信息不足等）
  final List<String> sources; // 引用条文/出处
  const DiagnosisResult({
    this.jing = '',
    this.suggestedFormula = '',
    this.message = '',
    this.sources = const [],
  });
}

class DiagnosticEngine {
  static DiagnosisResult evaluate(SymptomInput s) {
    if (s.cold == ColdState.unknown && s.sweat == SweatState.unknown) {
      return const DiagnosisResult(message: '需要更多症状才能辨证（至少提供寒热或汗出情况）');
    }

    // 太阳病
    if ((s.cold == ColdState.aversionToCold || s.cold == ColdState.aversionToWind) &&
        s.painNeck) {
      if (s.sweat == SweatState.hasSweat) {
        return const DiagnosisResult(
          jing: '太阳病',
          suggestedFormula: '桂枝汤方向',
          sources: ['伤寒论·太阳病提纲', '伤寒论·第2条（太阳中风）'],
          message: '有汗恶风 → 太阳中风，桂枝汤解肌。',
        );
      }
      if (s.sweat == SweatState.noSweat) {
        return const DiagnosisResult(
          jing: '太阳病',
          suggestedFormula: '麻黄汤方向',
          sources: ['伤寒论·太阳病提纲', '伤寒论·第3条（太阳伤寒）'],
          message: '无汗恶寒、体痛 → 太阳伤寒，麻黄汤发汗。',
        );
      }
    }
    return const DiagnosisResult(message: '尚未匹配到明确辨证，请补充更多症状。');
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `cd app && flutter test test/diagnostic_engine_test.dart`
Expected: `3 passed`。

- [ ] **Step 5: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/rules/diagnostic_engine.dart app/test/diagnostic_engine_test.dart
git commit -m "feat: rule-based diagnostic engine"
```

### Task 17: UI — Home 双 Tab + 问答视图 + 诊断问卷

**Files:**
- Modify: `/Users/heroims/Desktop/yi/app/lib/ui/home_page.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/ui/qa_tab.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/ui/diagnosis_tab.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/ui/widgets/disclaimer_banner.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/ui/widgets/source_list.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/widget_test.dart`

- [ ] **Step 1: 写 widget 测试**

```dart
// app/test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/app.dart';

void main() {
  testWidgets('app shows two tabs and disclaimer', (tester) async {
    await tester.pumpWidget(const NihaixiaApp());
    expect(find.text('自由问答'), findsOneWidget);
    expect(find.text('引导式诊断'), findsOneWidget);
    expect(find.textContaining('仅供学习参考'), findsWidgets);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/widget_test.dart`
Expected: FAIL（当前 HomePage 只有占位）。

- [ ] **Step 3: 实现 disclaimer_banner.dart**

```dart
import 'package:flutter/material.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.all(8),
      child: const Text(
        '本 App 为倪海厦中医教学知识整理，仅供学习参考，不构成医疗建议。'
        '如有急症或不适，请立即就医。',
        style: TextStyle(fontSize: 12, color: Colors.brown),
      ),
    );
  }
}
```

- [ ] **Step 4: 实现 source_list.dart**

```dart
import 'package:flutter/material.dart';

class SourceList extends StatelessWidget {
  final List<String> sources;
  const SourceList({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('（来源）', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final s in sources.take(5))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: InkWell(
              onTap: () {},
              child: Text('· $s', style: const TextStyle(color: Colors.blue)),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 5: 实现 qa_tab.dart（检索回答，纯 UI 骨架）**

```dart
import 'package:flutter/material.dart';
import 'widgets/disclaimer_banner.dart';

class QaTab extends StatefulWidget {
  const QaTab({super.key});
  @override
  State<QaTab> createState() => _QaTabState();
}

class _QaTabState extends State<QaTab> {
  final _controller = TextEditingController();
  String _answer = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ask() {
    // M5 接入检索链路（Task 18）
    setState(() {
      _answer = '（检索层尚未接线，将在 M5 完成。输入：${_controller.text.trim()}）';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const DisclaimerBanner(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Text(_answer.isEmpty ? '输入问题，如「小柴胡汤什么时候用」' : _answer),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: '问倪海厦经方…', border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: _ask, child: const Text('问')),
        ]),
      ),
    ]);
  }
}
```

- [ ] **Step 6: 实现 diagnosis_tab.dart（问卷分步骨架，M5 接规则引擎）**

```dart
import 'package:flutter/material.dart';
import 'widgets/disclaimer_banner.dart';
import '../rules/diagnostic_engine.dart';

class DiagnosisTab extends StatefulWidget {
  const DiagnosisTab({super.key});
  @override
  State<DiagnosisTab> createState() => _DiagnosisTabState();
}

class _DiagnosisTabState extends State<DiagnosisTab> {
  final SymptomInput _input = const SymptomInput();
  DiagnosisResult? _result;
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const DisclaimerBanner(),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(_buildSurvey(), style: const TextStyle(fontSize: 16)),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Text('辨证：${_result!.jing}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_result!.message),
            if (_result!.suggestedFormula.isNotEmpty)
              Text('代表方方向：${_result!.suggestedFormula}'),
          ],
        ]),
      ),
    ]);
  }

  String _buildSurvey() => '引导式诊断（步骤 $_step）\n'
      '请依次回答：\n1. 怕冷还是怕热？2. 有汗还是没汗？\n'
      '3. 是否头痛/脖子痛？4. 是否口渴？\n'
      '（本步骤 M5 接入问卷选项与规则引擎）';
}
```

- [ ] **Step 7: 实现 home_page.dart（双 Tab）**

```dart
import 'package:flutter/material.dart';
import 'qa_tab.dart';
import 'diagnosis_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('倪海厦中医问答')),
      body: IndexedStack(index: _index, children: const [QaTab(), DiagnosisTab()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: '自由问答'),
          NavigationDestination(icon: Icon(Icons.healing), label: '引导式诊断'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: 跑测试确认通过**

Run: `cd app && flutter test`
Expected: 全部通过（含 widget_test）。

- [ ] **Step 9: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/ui/ app/test/widget_test.dart
git commit -m "feat: home tabs, qa and diagnosis UI skeleton"
```

---

## M5：端侧 LLM 接入（RAG 合成 + 降级）

### Task 18: 检索链路接线（QA Tab 真正问答）

**Files:**
- Modify: `/Users/heroims/Desktop/yi/app/lib/ui/qa_tab.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/retrieval_integration_test.dart`

- [ ] **Step 1: 写集成测试（内存库 FTS + 意图路由 + 组装）**

```dart
// app/test/retrieval_integration_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/retrieval/searcher.dart';
import 'package:nihaixia_app/retrieval/structured_queries.dart';
import 'package:nihaixia_app/retrieval/intent_router.dart';
import 'package:nihaixia_app/retrieval/answer_assembler.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';

void main() {
  test('方剂查询走结构化表', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.herbs).insert(HerbsCompanion.insert(name: '甘草', taste: const Value('甘平')));
    await db.into(db.herbs).insert(HerbsCompanion.insert(name: '大枣', taste: const Value('甘温')));
    final svc = QaService(db);
    final answer = await svc.answer('甘草有什么作用');
    expect(answer.hasAnswer, true);
    expect(answer.sources, isNotEmpty);
    await db.close();
  });

  test('开放问题走 FTS 兜底', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
      source: '黄帝内经',
      heading: '上古天真论',
      text: '上古之人，其知道者，法于阴阳，和于术数。',
      tokens: const Value('上古 之 人 其 知道 者 法 于 阴阳 和 于 术数'),
    ));
    await ensureFts(db);
    await db.customStatement(
        "INSERT INTO chunks_fts(rowid, text) SELECT 1, '上古之人，其知道者，法于阴阳，和于术数。'");
    final svc = QaService(db);
    final answer = await svc.answer('什么是法于阴阳');
    expect(answer.hasAnswer, true);
    expect(answer.sources.first.source, '黄帝内经');
    await db.close();
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/retrieval_integration_test.dart`
Expected: FAIL（qa_service 不存在）。

- [ ] **Step 3: 实现 qa_service.dart**

```dart
import 'dart:async';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/retrieval/intent_router.dart';
import 'package:nihaixia_app/retrieval/searcher.dart';
import 'package:nihaixia_app/retrieval/structured_queries.dart';
import 'package:nihaixia_app/retrieval/answer_assembler.dart';

class QaResult {
  final bool hasAnswer;
  final String answer;
  final List<SearchHit> sources;
  const QaResult({required this.hasAnswer, this.answer = '', this.sources = const []});
}

class QaService {
  final Database db;
  QaService(this.db);

  Future<QaResult> answer(String query) async {
    final intent = IntentRouter.classify(query);
    try {
      if (intent == Intent.herbFormula) {
        final herbs = await StructuredQueries.findHerbs(db, query);
        if (herbs.isNotEmpty) {
          final text = herbs.map((h) => '${h.name}：${h.taste ?? ''} ${h.indications ?? ''}').join('\n');
          final src = herbs.map((h) => '神农本草经·${h.name}').toList();
          return QaResult(hasAnswer: true, answer: text, sources: src.map((s) => SearchHit(source: s, heading: '', text: '')).toList());
        }
      }
      final hits = await Searcher.searchByFts(db, query);
      if (hits.isNotEmpty) {
        final text = AnswerAssembler.formatSnippet(
          sources: hits.map((h) => '${h.source}·${h.heading}').toList(),
          answer: hits.take(3).map((h) => h.text).join('\n\n'),
        );
        return QaResult(hasAnswer: true, answer: text, sources: hits.take(3));
      }
      return const QaResult(hasAnswer: false, answer: '资料中未找到相关内容。');
    } catch (_) {
      return const QaResult(hasAnswer: false, answer: '检索出现异常，请重试。');
    }
  }
}
```

- [ ] **Step 4: 更新 qa_tab.dart 接线**

`QaTab` 注入 `QaService`（通过构造参数；App 层后续 DI）。替换 `_ask` ：

```dart
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'package:nihaixia_app/retrieval/searcher.dart';

class QaTab extends StatefulWidget {
  final QaService? service;
  const QaTab({super.key, this.service});
  ...
}

void _ask() {
  final q = _controller.text.trim();
  if (q.isEmpty) return;
  setState(() => _answer = '检索中…');
  // 用注入的 service；为保持 widget 可测，未注入时给出占位
  _service.fold(
    (s) async {
      final r = await s.answer(q);
      if (mounted) setState(() => _answer = r.answer);
    },
    () => setState(() => _answer = '（未接线，输入：$q）'),
  );
}
```

> 注：`_service` 为 `Option<QaService>`（null 安全）。简化实现：`final QaService? service;`，未注入则占位。

- [ ] **Step 5: 跑测试确认通过**

Run: `cd app && flutter test`
Expected: 集成测试 + 既有测试全部通过。

- [ ] **Step 6: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/retrieval/qa_service.dart app/lib/ui/qa_tab.dart app/test/retrieval_integration_test.dart
git commit -m "feat: wire qa service end-to-end (retrieval only)"
```

### Task 19: 端侧 LLM 服务（llama_cpp_dart 抽象封装 + 降级接口）

**Files:**
- Create: `/Users/heroims/Desktop/yi/app/lib/llm/llm_service.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/llm/prompt_templates.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/llm/rag_synthesizer.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/llm_test.dart`

> 依赖版本：llama_cpp_dart `^0.2.2`（latest）。SDK 提供三档 API：
> - 低层 ffi、中层层级封装（`Llama` 类）、隔离岛封装（`LlamaParent`/`LlamaChild`）。
> - iOS/Android 使用隔离岛封装最稳（不阻塞 UI）。Task 20 用 `LlamaParent`。

- [ ] **Step 1: 加依赖 + 写测试**

pubspec 加：

```yaml
  llama_cpp_dart: ^0.2.2
```

`app/test/llm_test.dart`：

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/llm/prompt_templates.dart';
import 'package:nihaixia_app/llm/llm_service.dart';

void main() {
  test('prompt 包含资料与要求', () {
    final p = PromptTemplates.rag(
      question: '桂枝汤什么时候用？',
      evidences: ['桂枝汤主太阳中风。'],
    );
    expect(p, contains('桂枝汤什么时候用'));
    expect(p, contains('仅基于以下资料'));
    expect(p, contains('桂枝汤主太阳中风'));
  });

  test('llm service 模型文件不存在时 isAvailable=false', () {
    final svc = LlmService(modelPath: '/nonexistent.gguf');
    expect(svc.isAvailable, false);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter pub get && flutter test test/llm_test.dart`
Expected: FAIL（模块不存在）。

- [ ] **Step 3: 实现 prompt_templates.dart**

```dart
class PromptTemplates {
  static String rag({required String question, required List<String> evidences}) {
    final buf = StringBuffer()
      ..writeln('你是倪海厦经方中医助手。请仅基于以下资料回答问题。')
      ..writeln('不要编造资料中不存在的内容。')
      ..writeln()
      ..writeln('【资料】');
    for (final e in evidences.take(8)) {
      buf.writeln('- $e');
    }
    buf
      ..writeln()
      ..writeln('【问题】$question')
      ..writeln()
      ..writeln('要求：1) 只依据资料回答 2) 结尾注明出处 3) 资料不足时明确说"资料中未找到"。');
    return buf.toString();
  }
}
```

- [ ] **Step 4: 实现 llm_service.dart（抽象层，Task 20 已含真实实现）**

```dart
import 'dart:async';
import 'dart:io';

/// llama_cpp_dart 轻封装，对外契约：isAvailable + generate。
/// Task 20 已提供基于 LlamaParent（隔离岛）的真实实现，此处仅留接口，
/// 避免同一文件出现两套实现。
```

> 该文件真实实现直接见 Task 20 Step 3-4 的完整代码（含 LLM_CONTRACT 注解）。
> 本 Task 只需先落一个最小可用版本让测试通过：

```dart
import 'dart:io';

class LlmService {
  final String modelPath;
  final int ctxSize;
  bool _failed = false;

  LlmService({required this.modelPath, this.ctxSize = 2048});

  bool get isAvailable => !_failed && File(modelPath).existsSync();

  /// 同步返回可用状态（测试用）。
  void markUnavailable() => _failed = true;

  /// 真实实现见 Task 20；这里保持契约存在返回 null。
  Future<String?> generate(String prompt) async {
    if (!isAvailable) return null;
    throw UnimplementedError('真实推理在 Task 20 落位');
  }
}
```

- [ ] **Step 5: 实现 rag_synthesizer.dart**

```dart
import 'prompt_templates.dart';
import 'llm_service.dart';

class RagSynthesizer {
  final LlmService llm;
  RagSynthesizer(this.llm);

  bool get enabled => llm.isAvailable;

  Future<String?> synthesize({
    required String question,
    required List<String> evidences,
  }) async {
    if (!enabled) return null;
    final prompt = PromptTemplates.rag(question: question, evidences: evidences);
    return llm.generate(prompt);
  }
}
```

- [ ] **Step 6: 跑测试确认通过**

Run: `cd app && flutter test test/llm_test.dart`
Expected: `2 passed`。

- [ ] **Step 7: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/llm/ pubspec.yaml pubspec.lock app/test/llm_test.dart
git commit -m "feat: llm service abstraction with fallback"
```

### Task 20: llama_cpp_dart 真实推理（隔离岛 LlamaParent）+ 模型打包

**Files:**
- Modify: `/Users/heroims/Desktop/yi/app/lib/llm/llm_service.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/llm/llm_runner.dart`
- Create: `/Users/heroims/Desktop/yi/app/assets/models/README.md`
- Create: `/Users/heroims/Desktop/yi/app/test/llm_real_test.dart`

> 前置知识：llama_cpp_dart `^0.2.2` 隔离岛 API 用法（官方 example）：
>
> ```dart
> Llama.libraryPath = "bin/.../libllama.dylib";   // 移动端由插件 bundle 提供
> final loadCommand = LlamaLoad(
>   path: "path/to/model.gguf",
>   modelParams: ModelParams(),
>   contextParams: contextParams,
>   samplingParams: samplerParams,
> );
> final parent = LlamaParent(loadCommand);
> await parent.init();
> // 等待 status == LlamaStatus.ready（轮询，参考官方 chat_cli_isolated）
> parent.stream.listen((token) => sb.write(token));
> parent.completions.listen((event) { /* done */ });
> await parent.sendPrompt(prompt);
> // 等 completion 事件后取 sb 全文
> ```

- [ ] **Step 1: 下载 Qwen3 1.7B GGUF（手动步骤）**

```bash
# 在 app/assets/models/ 下准备（约 1.1GB，不入 git）
# 来源: HuggingFace 社区 GGUF 版 Qwen3-1.7B-Instruct Q4_K_M。
# 下载后用 sha256 核验，并把模型文件名记入 lib/core/config.dart。
```

`app/assets/models/README.md`：

```markdown
# 端侧模型

本目录放置 Qwen3-1.7B-Instruct Q4_K_M GGUF（约 1.1GB），
由开发机手动下载，`.gitignore` 已排除 `*.gguf`。

建议来源：HuggingFace `Qwen/Qwen3-1.7B-instruct` 社区 GGUF 量化版。
模型放入后，在模拟器/真机运行 `flutter test integration_test` 验证。
```

- [ ] **Step 2: 实现 llm_runner.dart（隔离岛 Runner）**

```dart
// app/lib/llm/llm_runner.dart
import 'dart:async';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

/// 基于 LlamaParent 隔离岛的单轮生成。
class LlmRunner {
  LlamaParent? _parent;
  bool _disposed = false;

  Future<void> ensureLoaded({
    required String modelPath,
    int nCtx = 2048,
    double temp = 0.3,
  }) async {
    if (_parent != null) return;
    final ctx = ContextParams()
      ..nCtx = nCtx
      ..nPredict = -1
      ..nBatch = 512;
    final sampler = SamplerParams()
      ..temp = temp
      ..topK = 40
      ..topP = 0.9;
    final load = LlamaLoad(
      path: modelPath,
      modelParams: ModelParams(),
      contextParams: ctx,
      samplingParams: sampler,
    );
    final parent = LlamaParent(load);
    await parent.init();
    // 等待就绪（最多 120 秒）
    for (var i = 0; i < 240; i++) {
      if (parent.status == LlamaStatus.ready) break;
      if (parent.status == LlamaStatus.error) {
        parent.dispose();
        throw StateError('模型加载失败: $modelPath');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    _parent = parent;
  }

  /// 生成全文（直到 completion 或超时）。
  Future<String> generate(String prompt, {Duration timeout = const Duration(seconds: 120)}) async {
    final parent = _parent;
    if (parent == null) throw StateError('模型未加载');
    final sb = StringBuffer();
    final done = Completer<void>();
    final sub = parent.stream.listen((t) => sb.write(t));
    parent.completions.listen((e) {
      if (!done.isCompleted) done.complete();
    });
    await parent.sendPrompt(prompt);
    await done.future.timeout(timeout, onTimeout: () {});
    await sub.cancel();
    return sb.toString();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _parent?.dispose();
    _parent = null;
  }
}
```

- [ ] **Step 3: 更新 llm_service.dart 使用 LlmRunner（真实实现，替换抽象版）**

```dart
// app/lib/llm/llm_service.dart
import 'dart:io';
import 'llm_runner.dart';

class LlmService {
  final String modelPath;
  final int ctxSize;
  LlmRunner? _runner;
  bool _loaded = false;

  LlmService({required this.modelPath, this.ctxSize = 2048});

  bool get isAvailable => File(modelPath).existsSync();

  Future<String?> generate(String prompt) async {
    if (!isAvailable) return null;
    try {
      _runner ??= LlmRunner();
      await _runner!.ensureLoaded(modelPath: modelPath, nCtx: ctxSize);
      _loaded = true;
      return await _runner!.generate(prompt);
    } catch (e) {
      // 降级：清空 runner，后续调用走检索层
      _runner?.dispose();
      _runner = null;
      return null;
    }
  }

  Future<void> dispose() async {
    _runner?.dispose();
    _runner = null;
  }
}
```

> 降级语义：模型文件缺失、加载失败、推理异常任一情况，`generate` 返回 null，
> QaService 据此 fallback 到检索原文（Task 21 已接线）。**App 永不因为 LLM 不可用而崩溃。**

- [ ] **Step 4: 保留抽象测试，新增真实推理测试（tag real）**

`app/test/llm_real_test.dart`：

```dart
@Tags(['real'])
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/llm/llm_service.dart';

void main() {
  test('real model generates', () async {
    const modelPath = 'assets/models/qwen3-1.7b-instruct-q4_k_m.gguf';
    final llm = LlmService(modelPath: modelPath);
    expect(llm.isAvailable, true);
    final out = await llm.generate('请回答：1+1等于几？');
    expect(out, isNotNull);
    expect(out, contains('2'));
  }, tags: ['real']);
}
```

- [ ] **Step 5: 运行真实推理冒烟**

```bash
cd /Users/heroims/Desktop/yi/app
# 桌面 dart 验证（macOS 目标可选）：
dart -c run  # 或 flutter test --tags real
```

Expected: `2` 输出（若 native 库链路有环境问题，先确保 `forceUnavailable/降级` 路径可用，此项可顺延，但**不可留未实现代码**——降级逻辑必须完整）。

- [ ] **Step 6: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/llm/ app/assets/models/README.md app/test/llm_real_test.dart
git commit -m "feat: real llama.cpp inference via LlamaParent"
```

### Task 21: RAG 合成降级链路（接入 QA）

**Files:**
- Modify: `/Users/heroims/Desktop/yi/app/lib/retrieval/qa_service.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/rag_integration_test.dart`

- [ ] **Step 1: 写测试（mock LLM 不可用 → 走检索原文）**

```dart
// app/test/rag_integration_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'package:nihaixia_app/llm/llm_service.dart';
import 'package:nihaixia_app/llm/rag_synthesizer.dart';

void main() {
  test('LLM 不可用时 QA 返回检索原文摘要', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.herbs).insert(HerbsCompanion.insert(name: '麻黄', taste: const Value('辛微苦温')));
    final llm = LlmService(modelPath: '/nonexistent.gguf'); // not available
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    final r = await svc.answer('麻黄性味');
    expect(r.hasAnswer, true);
    expect(r.answer, contains('麻黄'));
    await db.close();
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/rag_integration_test.dart`
Expected: FAIL。

- [ ] **Step 3: 修改 QaService 支持可注入 synthesizer**

```dart
import 'package:nihaixia_app/llm/rag_synthesizer.dart';

class QaService {
  final Database db;
  final RagSynthesizer? synthesizer;
  QaService(this.db, {this.synthesizer});

  Future<QaResult> answer(String query) async {
    // ...（原有逻辑不变）
    // 命中证据后，若 synthesizer 可用，用其合成自然语言回答；否则用原文拼装
    final synth = synthesizer;
    if (synth != null && synth.enabled) {
      final out = await synth.synthesize(
        question: query,
        evidences: hits.take(8).map((h) => h.text).toList(),
      );
      if (out != null) {
        return QaResult(hasAnswer: true, answer: out, sources: hits.take(3));
      }
    }
    return QaResult(hasAnswer: true, answer: _rawAnswer(hits), sources: hits.take(3));
  }

  String _rawAnswer(List<SearchHit> hits) {
    return AnswerAssembler.formatSnippet(
      sources: hits.map((h) => '${h.source}·${h.heading}').toList(),
      answer: hits.take(3).map((h) => h.text).join('\n\n'),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `cd app && flutter test test/rag_integration_test.dart`
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/retrieval/qa_service.dart app/test/rag_integration_test.dart
git commit -m "feat: rag fallback path in qa service"
```

---

## M6：云端增强（可选）+ 合规 + 打磨

### Task 22: 云端配置存储 + OpenAI 兼容客户端

**Files:**
- Create: `/Users/heroims/Desktop/yi/app/lib/cloud/cloud_config.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/cloud/cloud_client.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/cloud/photo_analyzer.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/cloud/live_chat.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/cloud_test.dart`

- [ ] **Step 1: 写测试（不真正发网络，验证 URL 构造与开关逻辑）**

```dart
// app/test/cloud_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
import 'package:nihaixia_app/cloud/cloud_client.dart';

void main() {
  test('配置未设置时增强功能关闭', () {
    const cfg = CloudConfig(baseUrl: '', apiKey: '');
    expect(cfg.isEnabled, false);
    expect(CloudClient.isPhotoEnabled(cfg), false);
    expect(CloudClient.isLiveEnabled(cfg), false);
  });

  test('构造 OpenAI 兼容 chat 请求体', () {
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');
    final body = CloudClient.buildChatBody(cfg, messages: [
      {'role': 'user', 'content': '你好'},
    ], stream: false);
    expect(body['model'], 'gpt-4o-mini');
    expect(body['messages'], isA<List>());
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/cloud_test.dart`
Expected: FAIL（模块不存在）。

- [ ] **Step 3: 实现 cloud_config.dart**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class CloudConfig {
  final String baseUrl; // OpenAI 兼容 endpoint，形如 .../v1
  final String apiKey;
  final String defaultModel;
  const CloudConfig({
    this.baseUrl = '',
    this.apiKey = '',
    this.defaultModel = 'gpt-4o-mini',
  });

  bool get isEnabled => baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;
}

class CloudConfigStore {
  static const _keyBase = 'cloud_base_url';
  static const _keyKey = 'cloud_api_key';
  static const _keyModel = 'cloud_model';

  static Future<void> save(CloudConfig cfg) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyBase, cfg.baseUrl);
    await p.setString(_keyKey, cfg.apiKey);
    await p.setString(_keyModel, cfg.defaultModel);
  }

  static Future<CloudConfig> load() async {
    final p = await SharedPreferences.getInstance();
    return CloudConfig(
      baseUrl: p.getString(_keyBase) ?? '',
      apiKey: p.getString(_keyKey) ?? '',
      defaultModel: p.getString(_keyModel) ?? 'gpt-4o-mini',
    );
  }
}
  static Future<CloudConfig> load() async =>
      const CloudConfig(); // 默认关闭
}
```

- [ ] **Step 4: 实现 cloud_client.dart**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cloud_config.dart';

class CloudClient {
  static const _timeout = Duration(seconds: 30);

  static bool isPhotoEnabled(CloudConfig c) => c.isEnabled;
  static bool isLiveEnabled(CloudConfig c) => c.isEnabled;

  static Map<String, dynamic> buildChatBody(
    CloudConfig c, {
    required List<Map<String, String>> messages,
    bool stream = false,
    String? model,
  }) {
    return {
      'model': model ?? c.defaultModel,
      'messages': messages,
      'stream': stream,
    };
  }

  static Future<String> chat(
    CloudConfig c,
    List<Map<String, String>> messages, {
    bool stream = false,
  }) async {
    final uri = Uri.parse('${c.baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions');
    final resp = await http
        .post(
          uri,
          headers: {'Authorization': 'Bearer ${c.apiKey}', 'Content-Type': 'application/json'},
          body: jsonEncode(buildChatBody(c, messages: messages, stream: stream)),
        )
        .timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('云端请求失败: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return data['choices'][0]['message']['content'] as String;
  }
}
```

- [ ] **Step 5: 实现 photo_analyzer.dart / live_chat.dart**

```dart
// photo_analyzer.dart — 视觉模型描述舌象
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cloud_config.dart';

/// 上传图片 base64，让视觉模型返回舌质/舌苔描述。
class PhotoAnalyzer {
  static Future<String> describeTongue(
    CloudConfig c,
    String imageBase64,
  ) async {
    final uri = Uri.parse('${c.baseUrl}/chat/completions');
    final body = {
      'model': c.defaultModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': '请描述这张舌象照片的舌质（颜色/胖瘦）和舌苔（色/厚薄/津液），只客观描述，不下辨证结论。'},
            {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}},
          ],
        }
      ],
    };
    final resp = await http.post(uri,
        headers: {'Authorization': 'Bearer ${c.apiKey}', 'Content-Type': 'application/json'},
        body: jsonEncode(body)).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) throw Exception('图片分析失败');
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return data['choices'][0]['message']['content'] as String;
  }
}
```

```dart
// live_chat.dart — 流式（SSE）对话
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cloud_config.dart';

class LiveChat {
  /// 简单的非流式轮询（首版），流式 SSE 后续可优化。
  static Future<String> ask(CloudConfig c, String question) async {
    final messages = [
      {'role': 'system', 'content': '你是倪海厦视角的中医问答助手，回答简洁、口语化，最后建议咨询医师。'},
      {'role': 'user', 'content': question},
    ];
    return CloudClient.chat(c, messages);
  }
}
```

- [ ] **Step 6: 跑测试确认通过**

Run: `cd app && flutter test test/cloud_test.dart`
Expected: PASS。

- [ ] **Step 7: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/cloud/ app/test/cloud_test.dart pubspec.yaml
git commit -m "feat: optional cloud enhancement layer"
```

### Task 23: 设置页 + 免责声明 + 警告卡 + 关于页

**Files:**
- Create: `/Users/heroims/Desktop/yi/app/lib/ui/settings_tab.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/ui/widgets/warning_card.dart`
- Modify: `/Users/heroims/Desktop/yi/app/lib/ui/home_page.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/widget_test.dart`

- [ ] **Step 1: 加测试（Tab 含设置入口 + 警告卡渲染）**

```dart
// widget_test.dart 追加（文件头需补 import 'package:nihaixia_app/ui/widgets/warning_card.dart';）
testWidgets('settings tab accessible', (tester) async {
  await tester.pumpWidget(const NihaixiaApp());
  expect(find.byIcon(Icons.settings), findsOneWidget);
});

testWidgets('emergency warning card renders', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: WarningCard())));
  expect(find.textContaining('立即就医'), findsOneWidget);
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/widget_test.dart`
Expected: FAIL。

- [ ] **Step 3: 实现 warning_card.dart**

```dart
import 'package:flutter/material.dart';

const _emergencyKeywords = ['胸痛', '呼吸困难', '呕血', '昏迷', '高热不退', '剧烈腹痛', '抽搐'];

class WarningCard extends StatelessWidget {
  final String? text;
  const WarningCard({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    final matched = text == null ? <String>[] :
        _emergencyKeywords.where(text!.contains).toList();
    if (matched.isEmpty) return const SizedBox.shrink();
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text('⚠ 检测到急危重症相关词（${matched.join('、')}），请立即就医。',
            style: TextStyle(color: Colors.red.shade800)),
      ),
    );
  }
}
```

- [ ] **Step 4: 实现 settings_tab.dart**

```dart
import 'package:flutter/material.dart';
import '../cloud/cloud_config.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});
  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _url = TextEditingController();
  final _key = TextEditingController();
  CloudConfig _cfg = const CloudConfig();

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('云端增强（默认关闭）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('配置 OpenAI 兼容 API 后可解锁：拍照看舌象、Live 对话。'),
      const SizedBox(height: 16),
      TextField(controller: _url, decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://api.example.com/v1')),
      const SizedBox(height: 8),
      TextField(controller: _key, decoration: const InputDecoration(labelText: 'API Key')),
      const SizedBox(height: 8),
      FilledButton(onPressed: _save, child: const Text('保存')),
      if (_cfg.isEnabled)
        const Padding(padding: EdgeInsets.only(top: 8), child: Text('✅ 已启用', style: TextStyle(color: Colors.green))),
      const Divider(),
      ListTile(leading: const Icon(Icons.info), title: const Text('关于'), subtitle: Text('知识库：nihaixia（MulanPSL-2.0）\n仅用于中医学习与研究')),
    ]);
  }

  void _save() {
    setState(() => _cfg = CloudConfig(baseUrl: _url.text.trim(), apiKey: _key.text.trim()));
    CloudConfigStore.save(_cfg);
  }
}
```

- [ ] **Step 5: 修改 home_page.dart 加入设置页**

把 `NavigationBar` destinations 扩展为三个 Tab：

```dart
destinations: const [
  NavigationDestination(icon: Icon(Icons.chat), label: '自由问答'),
  NavigationDestination(icon: Icon(Icons.healing), label: '引导式诊断'),
  NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
],
```

`IndexedStack` children 加 `SettingsTab()`。

- [ ] **Step 6: 跑测试确认通过**

Run: `cd app && flutter test`
Expected: 全部通过。

- [ ] **Step 7: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/ui/ app/test/widget_test.dart
git commit -m "feat: settings, warning card, about page"
```

### Task 24: 引导诊断问卷完成（选项交互 + 规则接线）

**Files:**
- Modify: `/Users/heroims/Desktop/yi/app/lib/ui/diagnosis_tab.dart`
- Test: `/Users/heroims/Desktop/yi/app/test/diagnosis_tab_test.dart`

- [ ] **Step 1: 写 widget 测试（选择汗/寒热选项 → 触发辨证 → 显示结果）**

```dart
// app/test/diagnosis_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/ui/diagnosis_tab.dart';

void main() {
  testWidgets('问卷三问后给出辨证', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DiagnosisTab())));
    // 问题1: 寒热
    await tester.tap(find.text('怕冷'));
    await tester.pump();
    // 问题2: 汗出
    await tester.tap(find.text('没汗'));
    await tester.pump();
    // 问题3: 头项/身体痛
    await tester.tap(find.text('头项强痛'));
    await tester.pump();
    expect(find.textContaining('太阳病'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/diagnosis_tab_test.dart`
Expected: FAIL（当前 tab 无选项）。

- [ ] **Step 3: 实现选项式问卷**

`diagnosis_tab.dart` 完整重写为选择卡片 + 步进：

```dart
import 'package:flutter/material.dart';
import '../rules/diagnostic_engine.dart';
import 'widgets/disclaimer_banner.dart';
import 'widgets/warning_card.dart';

class DiagnosisTab extends StatefulWidget {
  const DiagnosisTab({super.key});
  @override
  State<DiagnosisTab> createState() => _DiagnosisTabState();
}

class _DiagnosisTabState extends State<DiagnosisTab> {
  final _input = SymptomInput();
  DiagnosisResult? _result;
  int _q = 0;

  static const _questions = [
    '1/4 您怕冷、怕风，还是怕热？',
    '2/4 出汗情况？',
    '3/4 有头项/颈项强痛吗？',
    '4/4 有口渴或发热吗？',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const DisclaimerBanner(),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(_questions[_q], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._options(),
          const SizedBox(height: 16),
          if (_result != null)
            Card(elevation: 2, child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('辨证：${_result!.jing}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(_result!.message),
                if (_result!.suggestedFormula.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text('代表方方向：${_result!.suggestedFormula}')),
              ]),
            )),
          if (_result != null) const SizedBox(height: 8),
          if (_result != null) WarningCard(text: _result!.message),
        ]),
      ),
    ]);
  }

  List<Widget> _options() {
    switch (_q) {
      case 0:
        return [
          _choice('怕冷', () => _set(cold: ColdState.aversionToCold)),
          _choice('怕风', () => _set(cold: ColdState.aversionToWind)),
          _choice('怕热', () => _set(cold: ColdState.aversionToHeat)),
          _choice('不确定/跳过', _next),
        ];
      case 1:
        return [
          _choice('有汗', () => _set(sweat: SweatState.hasSweat)),
          _choice('没汗', () => _set(sweat: SweatState.noSweat)),
          _choice('不确定/跳过', _next),
        ];
      case 2:
        return [
          _choice('头项强痛', () => _set(painNeck: true)),
          _choice('身体酸痛', () => _set(bodyAche: true)),
          _choice('都没有/跳过', _next),
        ];
      default:
        return [
          _choice('口渴', () => _set(thirst: true)),
          _choice('发热', () => _set(fever: true)),
          _choice('都没有/完成辨证', _finish),
        ];
    }
  }

  Widget _choice(String label, VoidCallback onTap) =>
      Card(child: ListTile(title: Text(label), onTap: onTap));

  void _set({SweatState? sweat, ColdState? cold, bool? painNeck, bool? bodyAche, bool? thirst, bool? fever}) {
    _input = SymptomInput(
      sweat: sweat ?? _input.sweat,
      cold: cold ?? _input.cold,
      painNeck: painNeck ?? _input.painNeck,
      bodyAche: bodyAche ?? _input.bodyAche,
      thirst: thirst ?? _input.thirst,
      fever: fever ?? _input.fever,
    );
    _next();
  }

  void _next() => setState(() {
        if (_q < _questions.length - 1) _q++;
        else _finish();
      });

  void _finish() => setState(() {
        _result = DiagnosticEngine.evaluate(_input);
      });
}
```

> 注：`_input` 需改为非 final 字段（`SymptomInput _input = const SymptomInput();`）。

- [ ] **Step 4: 跑测试确认通过**

Run: `cd app && flutter test test/diagnosis_tab_test.dart`
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/ui/diagnosis_tab.dart app/test/diagnosis_tab_test.dart
git commit -m "feat: guided diagnosis questionnaire wired to rule engine"
```

### Task 25: 数据库资产导入 + 内存监控降级

**Files:**
- Modify: `/Users/heroims/Desktop/yi/app/lib/core/database.dart`
- Create: `/Users/heroims/Desktop/yi/app/lib/core/db_loader.dart`
- Create: `/Users/heroims/Desktop/yi/app/test/db_loader_test.dart`

- [ ] **Step 1: 写测试（将 assets 中的 kb.sqlite3 拷贝到应用文档目录再打开）**

```dart
// app/test/db_loader_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/db_loader.dart';
import 'package:nihaixia_app/core/database.dart';

void main() {
  test('assets 库可被打开', () async {
    final db = await DbLoader.loadFromAssets();
    expect(db, isNotNull);
    final n = await db.customSelect('SELECT COUNT(*) c FROM herbs').getSingle();
    expect(n.read<int>('c') > 0, true);
    await db.close();
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd app && flutter test test/db_loader_test.dart`
Expected: FAIL（assets 库尚未生成 + db_loader 不存在）。先执行 Task 9 生成 `app/assets/kb/kb.sqlite3` 并放入 assets。

- [ ] **Step 3: 实现 db_loader.dart**

```dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:nihaixia_app/core/database.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class DbLoader {
  /// 从 assets 拷贝 kb.sqlite3 到应用支持目录并打开。
  static Future<AppDatabase> loadFromAssets() async {
    final dir = await getApplicationSupportDirectory();
    final target = p.join(dir.path, 'kb.sqlite3');
    if (!await File(target).exists()) {
      final data = await rootBundle.load('assets/kb/kb.sqlite3');
      await File(target).writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    final db = AppDatabase(NativeDatabase(File(target)));
    return db;
  }
}
```

- [ ] **Step 4: 内存监控降级辅助**

`app/lib/core/capability.dart`：

```dart
// 设备算力检测：低内存机型禁用 LLM（M5 的降级点）
class DeviceCapability {
  /// 占位：后续接 DeviceInfoPlugin。当前按 4GB 阈值。
  static bool get canRunLocalLlm {
    // Android: 通过 ActivityManager.getMemoryClass()；iOS: processInfo
    // 简化：统一返回 true，由 LlmService.isAvailable（模型文件存在）二次把关。
    return true;
  }
}
```

- [ ] **Step 5: 更新 database.dart 允许外部传入文件**

保持现有 `AppDatabase(super.e)` 构造兼容；`loadFromAssets` 即为生产入口。

- [ ] **Step 6: 跑测试确认通过（需要先有 assets kb 文件）**

Run: `cd app && flutter test test/db_loader_test.dart`
Expected: PASS。

- [ ] **Step 7: 提交**

```bash
cd /Users/heroims/Desktop/yi
git add app/lib/core/db_loader.dart app/lib/core/capability.dart app/test/db_loader_test.dart
git commit -m "feat: load assets db and capability gate"
```

### Task 26: QA 全链路真机验证 + README 使用说明

**Files:**
- Modify: `/Users/heroims/Desktop/yi/README.md`
- Modify: `/Users/heroims/Desktop/yi/app/lib/main.dart`（接线：loadFromAssets + QaService + 降级日志）

- [ ] **Step 1: 组装 main.dart**

```dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/db_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DbLoader.loadFromAssets().then((db) {
    runApp(NihaixiaApp(database: db));
  }).catchError((e) {
    // 数据库不可用仍可启动（检索层会降级提示）
    runApp(const NihaixiaApp());
  });
}
```

`app.dart` 接收 `AppDatabase?` 并下传给 `QaTab`：

```dart
class NihaixiaApp extends StatelessWidget {
  final AppDatabase? database;
  const NihaixiaApp({super.key, this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '倪海厦中医问答',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: HomePage(database: database),
    );
  }
}
```

`HomePage` 构造传 `db` 给 `QaTab`（`QaTab(db: db)`）；`QaTab` 在 `initState` 用 `db != null ? QaService(db!) : null` 初始化。

- [ ] **Step 2: 真机/模拟器跑通**

```bash
cd /Users/heroims/Desktop/yi/app
flutter run        # 手动验证：猜「小柴胡汤」、「感冒 怕冷 没汗」等
```

Expected: 检索问答可用；若模型文件未放入，App 自动降级为纯检索。

- [ ] **Step 3: 更新 README（构建工具 + App 使用方法）**

```markdown
## 构建流程
1. `cd tools && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`
2. `git clone --depth 1 https://github.com/jangviktor-web/nihaixia.git tools/data/nihaixia`
3. `.venv/bin/python build_kb.py --repo data/nihaixia --out out`
4. 把 `tools/out/kb.sqlite3` 拷到 `app/assets/kb/kb.sqlite3`
5. 下载 Qwen3-1.7B Q4 GGUF 到 `app/assets/models/`
6. `cd app && flutter pub get && flutter run`

## 分层能力
- 纯检索：任意机型可用，可溯源
- 端侧 LLM RAG：有模型文件时自动启用
- 云端增强：设置页填 API Key 解锁拍照/Live
```

- [ ] **Step 4: 全部测试 + lint**

```bash
cd app
flutter analyze
flutter test
cd ../tools && .venv/bin/python -m pytest -q
```

Expected: 0 lint 错误，全部测试通过。

- [ ] **Step 5: 最终提交**

```bash
cd /Users/heroims/Desktop/yi
git add -A
git commit -m "feat: wire app bootstrap, docs, full test pass"
```

---

## 验收清单（对 spec 逐项）

| spec 需求 | 计划任务 |
|---|---|
| 知识库解析（herbs/formulas/tiao_wen/cases/acupoints/chunks） | Task 4-8 |
| 同义词表 + FTS5 + jieba token | Task 9,10 |
| 意图路由/BM25/结构化查询 | Task 13,14,15 |
| 规则引擎辨证 | Task 16 |
| 双 Tab UI + 免责声明 | Task 17 |
| QA 检索链路端到端 | Task 18 |
| 端侧 LLM 封装 + RAG + 降级 | Task 19,20,21 |
| 云端增强（拍照/Live）默认关闭 | Task 22 |
| 设置页 + 警告卡 + 关于页 | Task 23 |
| 引导问卷完整体验 | Task 24 |
| assets 库导入 + 算力门控 | Task 25 |
| 真机验证 + README | Task 26 |

**明确推迟/不做（YAGNI）**：账号、云同步、付费、多知识库、端侧多模态（spec §10）。
