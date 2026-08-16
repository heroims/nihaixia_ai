import 'package:drift/drift.dart';
import 'package:nihaixia_app/core/models.dart';

/// 检索器：对本地 raw_chunks 语料执行逐词 AND 子串搜索。
///
/// 不走 FTS5：对中文语料，unicode61 分词 recall 差且 App 端无分词器。
/// 改为按空格切词，每词 LIKE '%词%' 子串匹配，全部命中（AND 语义），
/// 结果按启发式评分降序。
class Searcher {
  /// 高优先级来源：诊断速查 / 临床经验等浓缩资料，命中时加权。
  static const _highPrioritySources = {
    '01-six-meridian-formulas.md',
    '02-acupuncture-quick-ref.md',
    '03-clinical-experience.md',
    '医案集',
  };

  /// 标题命中加分。
  static const int _headingBonus = 4;

  /// 高优先级来源命中加分。
  static const int _sourceBonus = 6;

  /// 对 raw_chunks.text 做逐词 AND LIKE '%词%' 子串匹配。
  /// query 空格分隔的词全部必须命中（AND 语义）。
  /// 结果按启发式评分降序。
  static Future<List<SearchHit>> searchRawChunks(
    DatabaseConnectionUser db,
    String query, {
    int limit = 8,
  }) async {
    final words = query
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .map((w) => w.trim())
        .toList();
    if (words.isEmpty || limit <= 0) return const [];

    final conditions = List.filled(words.length, 'text LIKE ?');
    final args = <Variable<Object>>[for (final w in words) Variable('%$w%')];

    // 放宽候选上限，保证评分截断前有足够素材（默认 3 倍）。
    final candidateLimit = limit * 3;
    final rows = await db.customSelect(
      'SELECT source, heading, text FROM raw_chunks '
      'WHERE ${conditions.join(' AND ')} LIMIT ?',
      variables: [...args, Variable(candidateLimit)],
    ).get();

    final hits = rows.map((r) {
      final source = r.read<String>('source');
      final heading = r.read<String>('heading');
      final text = r.read<String>('text');
      return _ScoredHit(
        SearchHit(source: source, heading: heading, text: text),
        _score(source, heading, text, words),
      );
    }).toList();

    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.take(limit).map((h) => h.hit).toList();
  }

  /// 启发式评分：词出现总次数 + 标题命中加分 + 来源白名单加分。
  static int _score(
    String source,
    String heading,
    String text,
    List<String> words,
  ) {
    var score = 0;
    for (final w in words) {
      score += _count(text, w);
    }
    if (words.any(heading.contains)) {
      score += _headingBonus;
    }
    if (_highPrioritySources.contains(source)) {
      score += _sourceBonus;
    }
    return score;
  }

  static int _count(String text, String word) {
    final count = text.split(word).length - 1;
    return count < 0 ? 0 : count;
  }
}

class _ScoredHit {
  final SearchHit hit;
  final int score;
  const _ScoredHit(this.hit, this.score);
}