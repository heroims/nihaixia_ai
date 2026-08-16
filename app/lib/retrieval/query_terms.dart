import 'package:nihaixia_app/retrieval/intent_router.dart';
import 'package:nihaixia_app/retrieval/synonyms.dart';

/// 查询词条拆分结果：强约束 [andTerms]（必须全部命中）与弱召回 [orTerms]。
class QueryTerms {
  final List<String> andTerms;
  final List<String> orTerms;

  const QueryTerms({required this.andTerms, required this.orTerms});

  static final RegExp _cjkRun = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF]+');

  /// 把用户 query 拆成 andTerms / orTerms：
  /// 1. Trim + 按空白切词，逐词做同义词归一
  /// 2. 命中已知术语（诊断/方剂关键词）的词 → 提取关键词进 andTerms
  /// 3. 规范化后整串的连续 CJK 段长 >4 → 交叠 2-gram 进 orTerms（保证无空格
  ///    长句也有召回锚点，且打分可区分相关度）
  /// 4. 两表去重
  static QueryTerms extract(String query) {
    final and = <String>[];
    final or = <String>[];

    final terms = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map(Synonyms.canonicalize)
        .toList();

    final keywords = [...IntentRouter.diagKeywords, ...IntentRouter.formulaKeywords];
    for (final term in terms) {
      for (final kw in keywords) {
        if (term.contains(kw) && !and.contains(kw)) and.add(kw);
      }
    }

    final continuous = terms.join();
    for (final m in _cjkRun.allMatches(continuous)) {
      final run = m.group(0)!;
      if (run.length <= 4) continue;
      for (var i = 0; i + 2 <= run.length; i++) {
        final gram = run.substring(i, i + 2);
        if (!or.contains(gram)) or.add(gram);
      }
    }

    return QueryTerms(andTerms: and, orTerms: or);
  }
}
