import 'package:nihaixia_app/retrieval/synonyms.dart';

enum Intent { diagnosis, herbFormula, general }

class IntentRouter {
  /// 症状/辨证术语（public：供 QueryTerms 拆分 andTerms）。
  static const diagKeywords = ['感冒', '怕冷', '没汗', '无汗', '有汗', '发热', '恶寒',
    '恶风', '口渴', '睡眠', '大便', '小便', '舌象', '脉象', '腹泻',
    '咳嗽', '头痛', '失眠', '便秘', '心悸', '呕吐', '头晕', '耳鸣',
    '腰痛', '自汗', '盗汗'];

  /// 方剂/药物术语（public：供 QueryTerms 拆分 andTerms）。
  static const formulaKeywords = ['汤', '方', '怎么用', '剂量', '什么时候用',
    '附子', '黄芪', '人参', '当归', '桂枝', '麻黄', '芍药'];

  static Intent classify(String query) {
    final q = query.trim();
    if (q.isEmpty) return Intent.general;
    // 先做同义词归一后匹配方剂名特征
    final canonical = Synonyms.canonicalize(q);
    final isDiag = _hasAny(diagKeywords, q) || _hasAny(diagKeywords, canonical);
    if (canonical.contains('汤') || _hasAny(formulaKeywords, q)) {
      // 但「感冒」等同时满足诊断关键词时，优先进诊断
      if (isDiag && !q.contains('汤')) {
        return Intent.diagnosis;
      }
      return Intent.herbFormula;
    }
    if (isDiag) return Intent.diagnosis;
    return Intent.general;
  }

  static bool _hasAny(List<String> kws, String text) =>
      kws.any((k) => text.contains(k));
}