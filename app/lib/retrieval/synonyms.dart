class Synonyms {
  static const Map<String, String> _table = {
    // 方剂别名（计划 Task 13）
    '柴胡汤': '小柴胡汤',
    '大柴胡': '大柴胡汤',
    '桂枝方': '桂枝汤',
    '麻黄方': '麻黄汤',
    '葛根方': '葛根汤',
    '小青龙': '小青龙汤',
    '大青龙': '大青龙汤',
    // 症状口语别名（Task 10 质量审查：语料用「无汗」「腹泻」「咽喉痛」正名）
    '没汗': '无汗',
    '没精神': '精神不振',
    '拉肚子': '腹泻',
    '闹肚子': '腹泻',
    '嗓子疼': '咽喉痛',
    '嗓子痛': '咽喉痛',
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