import 'package:nihaixia_app/retrieval/intent_router.dart';
import 'package:nihaixia_app/retrieval/synonyms.dart';

/// 查询词条拆分结果：强约束 [andTerms]（部分命中）与弱召回 [orTerms]（参与打分）。
class QueryTerms {
  final List<String> andTerms;
  final List<String> orTerms;

  /// 连续 CJK 整段短语（exact-phrase 信号）。是 [orTerms] 的子集：命中时在
  /// Searcher 里按 [+3] 加权（普通 2-gram 为 +1），让「整段命中」排在
  /// 「单个 2-gram 命中」之前（Fix C1/M2）。
  final List<String> wholeRuns;

  const QueryTerms({
    required this.andTerms,
    required this.orTerms,
    this.wholeRuns = const [],
  });

  static final RegExp _cjkRun =
      RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF]+');

  /// 功能词/弱词（Fix I3）：命中也不进 andTerms。汤/方/怎么用/用 这类词在语料中
  /// 命中率极高（汤 1370 行、方 1858 行），作强约束会拉回上千行噪声；它们仍进
  /// orTerms 参与打分，但真正的方剂语义由整段短语 orTerm 承担。
  static const Set<String> _weakTerms = {
    '汤',
    '方',
    '怎么用',
    '剂量',
    '什么时候用',
    '用',
  };

  /// 静态合并诊断+方剂关键词，避免每次 extract 重建（Fix M6）。
  static const List<String> _keywords = [
    ...IntentRouter.diagKeywords,
    ...IntentRouter.formulaKeywords,
  ];

  /// 把用户 query 拆成 andTerms / orTerms / wholeRuns：
  /// 1. Trim + 按空白切词，逐词做同义词归一
  /// 2. 命中已知术语（诊断/方剂/药材关键词）的词 → 提取关键词进 andTerms；
  ///    弱词（汤/方/怎么用/用 等）只进 orTerms
  /// 3. 规范化后整串的每个连续 CJK 段：整段作为 orTerm（长度 ≥2，exact-phrase
  ///    信号）；段长 >4 时额外补交叠 2-gram（保证无空格长句也有召回锚点，
  ///    且打分可区分相关度）
  /// 4. 两表去重
  static QueryTerms extract(String query) {
    final and = <String>[];
    final or = <String>[];
    final whole = <String>[];

    final terms = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map(Synonyms.canonicalize)
        .toList();

    for (final term in terms) {
      for (final kw in _keywords) {
        if (!term.contains(kw)) continue;
        if (_weakTerms.contains(kw)) {
          if (!or.contains(kw)) or.add(kw);
        } else if (!and.contains(kw)) {
          and.add(kw);
        }
      }
    }

    final continuous = terms.join();
    for (final m in _cjkRun.allMatches(continuous)) {
      final run = m.group(0)!;
      if (run.length < 2) continue;
      // Fix R2：过长的整段（>8 字）几乎不可能整段命中，且长句已由 2-gram 锚定，
      // 不再把整段加入 or/whole（避免无效的 +3 权重与 SQL 长串匹配）。
      if (run.length <= 8) {
        if (!or.contains(run)) or.add(run);
        if (!whole.contains(run)) whole.add(run);
      }
      if (run.length <= 4) continue;
      for (var i = 0; i + 2 <= run.length; i++) {
        final gram = run.substring(i, i + 2);
        if (!or.contains(gram)) or.add(gram);
      }
    }

    return QueryTerms(andTerms: and, orTerms: or, wholeRuns: whole);
  }
}
