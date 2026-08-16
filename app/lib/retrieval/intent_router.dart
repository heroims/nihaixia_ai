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