class Synonyms {
  // 部分名别名：柴胡汤 是 小/大柴胡汤 的子串，直接 replaceAll 会把
  // 小柴胡汤 叠加成 小小柴胡汤，故用负向回顾断言排除「大小」前缀。
  static final RegExp _chaihuTangRe = RegExp(r'(?<![大小])柴胡汤');

  static const Map<String, String> _table = {
    // 方剂别名（计划 Task 13）
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
    var result = text.replaceAll(_chaihuTangRe, '小柴胡汤');
    for (final entry in _table.entries) {
      if (!result.contains(entry.key)) continue;
      // 已含正名时跳过，避免 大柴胡汤→大柴胡汤汤 之类的叠加
      if (result.contains(entry.value)) continue;
      return result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}