import 'package:drift/drift.dart';
import 'package:nihaixia_app/core/models.dart';
import 'package:nihaixia_app/retrieval/query_terms.dart';

/// 检索器：对本地 raw_chunks 语料执行子串检索。
///
/// 不走 FTS5：对中文语料，unicode61 分词 recall 差且 App 端无分词器。
/// 方案：andTerms 逐词 AND LIKE 子串匹配（SQL 只过滤不强截断），orTerms 只
/// 参与打分（每命中 +1）不做过滤，全部候选在 Dart 侧启发式评分后取 limit 条。
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

  /// 便利入口：query 走 [QueryTerms.extract] 拆分后调用 [searchRawChunks]。
  static Future<List<SearchHit>> searchByQuery(
    DatabaseConnectionUser db,
    String query, {
    int limit = 8,
  }) async {
    final terms = QueryTerms.extract(query);
    return searchRawChunks(db, terms.andTerms,
        orTerms: terms.orTerms, limit: limit);
  }

  /// 对 raw_chunks.text 做 andTerms 逐词 AND LIKE 子串匹配。
  /// andTerms 全部必须命中（AND 语义）；orTerms 命中每个 +1 分（不参与过滤）。
  /// SQL 只负责过滤与确定排序，不设 LIMIT；Dart 侧评分后截取前 limit 条。
  static Future<List<SearchHit>> searchRawChunks(
    DatabaseConnectionUser db,
    List<String> andTerms, {
    List<String>? orTerms,
    int limit = 8,
  }) async {
    final ors = orTerms ?? const <String>[];
    if (andTerms.isEmpty && ors.isEmpty) return const [];
    if (limit <= 0) return const [];

    // LIKE 通配符转义：反斜杠、%、_ 都按字面匹配。
    String escape(String term) => term
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final escaped = [for (final t in andTerms) escape(t)];

    final conditions = List.filled(escaped.length, "text LIKE ? ESCAPE '\\'");
    final args = <Variable<Object>>[for (final t in escaped) Variable('%$t%')];

    // 全量拉取（不设 LIMIT），ORDER BY id 保证多次查询返回顺序确定。
    final rows = await db.customSelect(
      'SELECT id, source, heading, text FROM raw_chunks '
      '${escaped.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')} '}'
      'ORDER BY id',
      variables: args,
    ).get();

    final hits = <_ScoredHit>[];
    for (final r in rows) {
      final id = r.read<int>('id');
      final source = r.read<String>('source');
      final heading = r.read<String>('heading');
      final text = r.read<String>('text');

      // 至少命中一个词才算相关（andTerms 非空时 SQL 已保证，orTerms-only
      // 查询需在 Dart 侧过滤掉一个 2-gram 都没命中的行）。
      final matched = andTerms.isNotEmpty ||
          ors.any((t) => text.contains(t) || heading.contains(t));
      if (!matched) continue;

      hits.add(_ScoredHit(id, SearchHit(source: source, heading: heading, text: text),
          _score(source, heading, text, andTerms, ors)));
    }

    // 同分时按 id 升序，保证结果稳定。
    hits.sort((a, b) => b.score != a.score
        ? b.score.compareTo(a.score)
        : a.id.compareTo(b.id));
    return hits.take(limit).map((h) => h.hit).toList();
  }

  /// 启发式评分：andTerms 词频总和 + orTerms 命中数 + 标题命中加分 + 来源加分。
  static int _score(
    String source,
    String heading,
    String text,
    List<String> andTerms,
    List<String> orTerms,
  ) {
    var score = 0;
    for (final t in andTerms) {
      score += _count(text, t);
    }
    for (final t in orTerms) {
      if (text.contains(t) || heading.contains(t)) score += 1;
    }
    if (heading.isNotEmpty && (andTerms.any(heading.contains) || orTerms.any(heading.contains))) {
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
  const _ScoredHit(this.id, this.hit, this.score);
}
