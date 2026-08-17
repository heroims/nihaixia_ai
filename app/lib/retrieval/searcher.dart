import 'package:drift/drift.dart';
import 'package:nihaixia_app/core/models.dart';
import 'package:nihaixia_app/retrieval/query_terms.dart';

/// 检索器：对本地 raw_chunks 语料执行子串检索。
///
/// 不走 FTS5：对中文语料，unicode61 分词 recall 差且 App 端无分词器。
/// 方案：andTerms 走「and-only 的 text/heading OR LIKE」进 SQL（保留结果的
/// 超集，拉取行数从 and∪or 降到 and-only，约 8× 减少）；andTerms 为空时
/// 退化为 orTerms OR LIKE。行级「部分命中」过滤、启发式打分与排序在 Dart 侧
/// 完成，最后取 limit 条。
class Searcher {
  /// 来源白名单：source → 加分。浓缩资料（distilled 01/02/03）权重高；
  /// 医案集量大（约 520/2673 行），降为 +2 避免压过精炼条文。
  static const Map<String, int> _sourceBonus = {
    '01-six-meridian-formulas.md': 6,
    '02-acupuncture-quick-ref.md': 6,
    '03-clinical-experience.md': 6,
    '医案集': 2,
  };

  /// 标题命中加分。
  static const int _headingBonus = 4;

  /// 整段短语 orTerm 的加权分（Fix C1/M2）：让精确短语命中压过单个 2-gram 命中。
  static const int _wholeRunBonus = 3;

  /// 便利入口：query 走 [QueryTerms.extract] 拆分后调用 [searchRawChunks]。
  static Future<List<SearchHit>> searchByQuery(
    DatabaseConnectionUser db,
    String query, {
    int limit = 8,
  }) async {
    final terms = QueryTerms.extract(query);
    return searchRawChunks(db, terms.andTerms,
        orTerms: terms.orTerms, wholeRuns: terms.wholeRuns, limit: limit);
  }

  /// 对 raw_chunks.text 做子串检索。
  ///
  /// SQL WHERE 策略：andTerms 非空时只用 andTerms 的 OR LIKE 并集，且每个
  /// andTerm 同时匹配 text 与 heading（(text LIKE ? OR heading LIKE ?)）。
  /// 因为 Dart 保留条件 hitCount >= minHit >= 1——凡被保留的行必命中至少一个
  /// andTerm，故 and-only 过滤是保留结果的超集（不改变结果，仅减少拉取行数，
  /// Fix R2）；heading 进 WHERE 让「标题命中、正文未命中」的 andTerm 行被有
  /// 意识地拉取（Dart 侧本就计入 hitCount 与 +4 标题分）。andTerms 为空时
  /// 退化为 orTerms OR LIKE（Fix I2）。行级过滤在 Dart 侧。
  ///
  /// 部分命中（Fix I1）：多症状查询若严格 AND 几乎必然召回悬崖（感冒+发热+恶寒+
  /// 无汗+头痛 五个症状同时出现概率极低）。因此 [andTerms] 改为「至少命中
  /// [minMatch] 个不同词」即保留，默认阈值 N<=2 → 1（单/双症状召回不缩水，
  /// 感冒+怕冷 由严格 AND 的 ~14 行回到 OR 并集的 ~208 行，按命中数排序），
  /// N>=3 → ceil(N/2)（五行证候至少中三行）。[minMatch] 被夹取到 [1, N]：
  /// <=0 按 1 处理（命中 0 个 andTerm 的行永远不相关），>N 按 N（严格全命中）。
  /// 排序按 (命中 andTerms 数 desc, score desc, id asc)。
  static Future<List<SearchHit>> searchRawChunks(
    DatabaseConnectionUser db,
    List<String> andTerms, {
    List<String>? orTerms,
    List<String>? wholeRuns,
    int limit = 8,
    int? minMatch,
  }) async {
    final ors = orTerms ?? const <String>[];
    final whol = wholeRuns ?? const <String>[];
    final n = andTerms.length;

    if (n == 0 && ors.isEmpty) return const [];
    if (limit <= 0) return const [];

    // 不变量（Fix R2）：n > 0 时 minHit >= 1（命中 0 个 andTerm 的行永远不
    // 相关，不能因 minMatch<=0 被保留成近全库返回），上界收敛到 n（minMatch>n
    // 视作严格全命中）。n == 0 时走 orTerms 路径，minHit 不使用。
    final int minHit;
    if (n > 0) {
      minHit = (minMatch ?? (n <= 2 ? 1 : (n + 1) ~/ 2)).clamp(1, n).toInt();
    } else {
      minHit = 0;
    }

    // LIKE 通配符转义：反斜杠、%、_ 都按字面匹配（Fix M1 / 上一轮 Fix 3）。
    String escape(String term) => term
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');

    // SQL WHERE 策略：andTerms 非空时只对 andTerms 过滤（每词同时匹配 text 与
    // heading），因为保留条件 hitCount >= minHit >= 1，被保留的行必命中至少一个
    // andTerm，and-only 是保留结果的超集（结果不变，拉取行数 8× 减少）。
    // andTerms 为空时退化为 orTerms OR LIKE。仍不设 LIMIT、ORDER BY id 保证
    // 多次查询返回顺序确定。
    final String whereClause;
    final List<Variable<Object>> args;
    if (n > 0) {
      final escaped = [for (final t in andTerms.toSet()) escape(t)];
      whereClause = [
        for (final _ in escaped)
          "(text LIKE ? ESCAPE '\\' OR heading LIKE ? ESCAPE '\\')",
      ].join(' OR ');
      args = [
        for (final t in escaped) ...[
          Variable('%$t%'),
          Variable('%$t%'),
        ],
      ];
    } else {
      final escaped = [for (final t in ors) escape(t)];
      whereClause = [
        for (final _ in escaped) "text LIKE ? ESCAPE '\\'",
      ].join(' OR ');
      args = [for (final t in escaped) Variable('%$t%')];
    }

    final rows = await db.customSelect(
      'SELECT id, source, heading, text FROM raw_chunks '
      'WHERE $whereClause '
      'ORDER BY id',
      variables: args,
    ).get();

    final hits = <_ScoredHit>[];
    for (final r in rows) {
      final id = r.read<int>('id');
      final source = r.read<String>('source');
      final heading = r.read<String>('heading');
      final text = r.read<String>('text');

      // 命中不同 andTerms 的个数（text 或 heading 任一命中即计 1）。
      var hitCount = 0;
      for (final t in andTerms) {
        if (text.contains(t) || heading.contains(t)) hitCount++;
      }

      final bool keep;
      if (n == 0) {
        // 纯 orTerms 查询：至少命中一个 orTerm 才算相关（否则行不会进 SQL 结果）。
        keep = ors.any((t) => text.contains(t) || heading.contains(t));
      } else {
        keep = hitCount >= minHit;
      }
      if (!keep) continue;

      hits.add(_ScoredHit(id, SearchHit(source: source, heading: heading, text: text),
          _score(source, heading, text, andTerms, ors, whol), hitCount));
    }

    // 命中 andTerms 数多者优先 → 打分 → id 升序保证稳定。
    hits.sort((a, b) {
      if (b.hitCount != a.hitCount) return b.hitCount.compareTo(a.hitCount);
      if (b.score != a.score) return b.score.compareTo(a.score);
      return a.id.compareTo(b.id);
    });
    return hits.take(limit).map((h) => h.hit).toList();
  }

  /// 启发式评分：andTerms 词频总和 + orTerms 命中数（整段短语 +3）+ 标题加分 + 来源加分。
  static int _score(
    String source,
    String heading,
    String text,
    List<String> andTerms,
    List<String> orTerms,
    List<String> wholeRuns,
  ) {
    var score = 0;
    for (final t in andTerms) {
      score += _count(text, t);
    }
    // 注意：双重计数只发生在无空格/2-gram 场景——整段/2-gram orTerm 若恰好
    // 包含 andTerm（如 感冒发热 含 感冒），该 andTerm 会在 orTerms 里再计一次，
    // 这是有意的加权：命中多个信号的行本应靠前（Fix M3）。
    for (final t in orTerms) {
      if (text.contains(t) || heading.contains(t)) {
        score += wholeRuns.contains(t) ? _wholeRunBonus : 1;
      }
    }
    if (heading.isNotEmpty &&
        (andTerms.any(heading.contains) || orTerms.any(heading.contains))) {
      score += _headingBonus;
    }
    score += _sourceBonus[source] ?? 0;
    return score;
  }

  static int _count(String text, String term) {
    final count = text.split(term).length - 1;
    return count < 0 ? 0 : count;
  }
}

class _ScoredHit {
  final int id;
  final SearchHit hit;
  final int score;
  final int hitCount;
  const _ScoredHit(this.id, this.hit, this.score, this.hitCount);
}