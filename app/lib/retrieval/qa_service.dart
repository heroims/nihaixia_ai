import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/core/models.dart';
import 'package:nihaixia_app/retrieval/answer_assembler.dart';
import 'package:nihaixia_app/retrieval/intent_router.dart';
import 'package:nihaixia_app/retrieval/query_terms.dart';
import 'package:nihaixia_app/retrieval/searcher.dart';
import 'package:nihaixia_app/retrieval/structured_queries.dart';

class QaResult {
  final bool hasAnswer;
  final String answer;
  final List<SearchHit> sources;
  const QaResult({
    required this.hasAnswer,
    this.answer = '',
    this.sources = const [],
  });
}

/// 问答主链路：意图路由 → 结构化优先 / 子串兜底 → 组装答案。
///
/// 不依赖 FTS5（Task 10/14 重构后无 FTS 表）：主路径用 [Searcher.searchByQuery]
/// 的「and-only OR LIKE + Dart 侧部分命中过滤」；结构化表（herbs/formulas/
/// tiao_wen）作为 herbFormula 意图的补充优先路径。
class QaService {
  final AppDatabase db;
  QaService(this.db);

  Future<QaResult> answer(String query) async {
    final intent = IntentRouter.classify(query);
    try {
      // herbFormula 意图：先结构化查 herbs/formulas/tiao_wen，无命中再子串兜底。
      if (intent == Intent.herbFormula) {
        final structured = await _answerStructured(query);
        if (structured != null) return structured;
      }
      final hits = await Searcher.searchByQuery(db, query);
      if (hits.isNotEmpty) {
        final text = AnswerAssembler.formatSnippet(
          sources: hits.map((h) => '${h.source}·${h.heading}').toList(),
          answer: hits.take(3).map((h) => h.text).join('\n\n'),
        );
        return QaResult(hasAnswer: true, answer: text, sources: hits.take(3).toList());
      }
      return const QaResult(hasAnswer: false, answer: '资料中未找到相关内容。');
    } catch (_) {
      return const QaResult(hasAnswer: false, answer: '检索出现异常，请重试。');
    }
  }

  /// 结构化优先路径：先用整句 query 匹配各表，匹配不到再退到
  /// [QueryTerms.extract] 提取出的药材/方剂关键词（'甘草有什么作用' 整句
  /// 无法命中 herbs.name，需退到关键词 '甘草'）。三表全空返回 null 交由
  /// 主路径走 [Searcher.searchByQuery] 子串兜底。
  Future<QaResult?> _answerStructured(String query) async {
    final herbs = <Herb>[];
    final formulas = <Formula>[];
    final tiaoWen = <TiaoWenData>[];
    final keywords = <String>[query, ...QueryTerms.extract(query).andTerms];
    for (final kw in keywords) {
      herbs.addAll(await StructuredQueries.findHerbs(db, kw));
      formulas.addAll(await StructuredQueries.findFormulas(db, kw));
      tiaoWen.addAll(await StructuredQueries.findTiaoWen(db, kw));
      if (herbs.isNotEmpty || formulas.isNotEmpty || tiaoWen.isNotEmpty) break;
    }
    if (herbs.isEmpty && formulas.isEmpty && tiaoWen.isEmpty) return null;

    final buf = StringBuffer();
    for (final h in herbs) {
      final desc = '${h.taste ?? ''} ${h.indications ?? ''}'.trim();
      buf.writeln(desc.isEmpty ? h.name : '${h.name}：$desc');
    }
    for (final f in formulas) {
      final name = f.name ?? f.title ?? '';
      buf.writeln(f.keySymptoms.isEmpty ? name : '$name：${f.keySymptoms}');
    }
    for (final t in tiaoWen) {
      final head = '【${t.number}】${t.title ?? ''}';
      buf.writeln(t.body.isEmpty ? head : '$head ${t.body}');
    }

    final sources = <SearchHit>[
      for (final h in herbs)
        SearchHit(
          source: '神农本草经',
          heading: h.name,
          text: '${h.taste ?? ''} ${h.indications ?? ''}'.trim(),
        ),
      for (final f in formulas)
        SearchHit(
          source: f.sourceRef,
          heading: f.name ?? f.title ?? '',
          text: f.keySymptoms,
        ),
      for (final t in tiaoWen)
        SearchHit(source: t.source, heading: t.title ?? '', text: t.body),
    ];

    final text = AnswerAssembler.formatSnippet(
      sources: sources.map((s) => '${s.source}·${s.heading}').toList(),
      answer: buf.toString().trim(),
    );
    return QaResult(hasAnswer: true, answer: text, sources: sources);
  }
}