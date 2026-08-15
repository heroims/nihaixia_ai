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