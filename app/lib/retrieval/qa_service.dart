import 'package:flutter/foundation.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/core/models.dart';
import 'package:nihaixia_app/llm/rag_synthesizer.dart';
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

  /// 可注入的 RAG 合成器（可选）。未注入或 LLM 不可用时自动降级为原文拼装。
  final RagSynthesizer? synthesizer;

  QaService(this.db, {this.synthesizer});

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
        // RAG 合成：仅用于子串检索路径（结构化路径走 RAG 属 Task 23/26 产品
        // 决策，暂缓）。命中证据后若 synthesizer 可用，用其产出自然语言回答；
        // 空/空白/异常输出一律走下方原文降级——降级链必须完整：合成器异常
        // 不得跳到外层 catch 变成『检索出现异常』（那是检索层错误才用的文案）。
        final synth = synthesizer;
        if (synth != null && synth.enabled) {
          String? out;
          try {
            out = await synth.synthesize(
              question: query,
              evidences: hits.take(8).map((h) => '${h.source}·${h.heading}：${h.text}').toList(),
            );
          } catch (e) {
            // 合成器异常 → 与空输出同等处理，降级为原文拼装。
            debugPrint('[QaService] synthesizer failed, degrade to body: $e');
          }
          if (out != null && out.trim().isNotEmpty) {
            return QaResult(hasAnswer: true, answer: out, sources: hits.take(5).toList());
          }
        }
        // fallback：body-only 答案，直接拼接命中文本，出处由 QaResult.sources 结构
        // 性承载，QaTab 用 SourceList 渲染，不再把（来源）内嵌进 answer 字符串（T18-4）。
        final text = hits.take(5).map((h) => h.text).join('\n\n');
        if (text.trim().isEmpty) {
          // 仅标题命中（正文为空）的 chunk：无实质答案，按 formatEmpty 语义返回。
          return QaResult(hasAnswer: false, answer: AnswerAssembler.formatEmpty());
        }
        return QaResult(hasAnswer: true, answer: text, sources: hits.take(5).toList());
      }
      return QaResult(hasAnswer: false, answer: AnswerAssembler.formatEmpty());
    } catch (e) {
      debugPrint('[QaService] answer failed: $e');
      return const QaResult(hasAnswer: false, answer: '检索出现异常，请重试。');
    }
  }

  /// 结构化优先路径：先用整句 query 匹配各表，匹配不到再退到
  /// [QueryTerms.extract] 提取出的药材/方剂关键词（'甘草有什么作用' 整句
  /// 无法命中 herbs.name，需退到关键词 '甘草'）。三表全空返回 null 交由
  /// 主路径走 [Searcher.searchByQuery] 子串兜底。
  ///
  /// 已知局限（T18-5，设计暂缓，不修）：'小柴胡汤什么时候用' 经
  /// [QueryTerms.extract] 得 andTerms=柴胡，findHerbs 命中 茈胡 +
  /// findTiaoWen 命中 99 行且无排序（噪声），未做排序/噪声抑制，交由
  /// Task 21（RAG 证据）与 Task 22（云端 LLM 排序）处理。
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
      buf.writeln(desc.isEmpty ? _herbDisplayName(h.name) : '${_herbDisplayName(h.name)}：$desc');
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
          heading: _herbDisplayName(h.name),
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

    final text = buf.toString().trim();
    return QaResult(hasAnswer: true, answer: text, sources: sources);
  }

  /// 古名 → 现代名（显示用）：herbs.name 存神农本草经古名（茈胡），用户多输
  /// 现代名（柴胡）检索，展示时补现代名提示，避免『茈胡』对用户晦涩。
  /// 由 [StructuredQueries.herbAliases] 反推，避免双份别名表漂移。
  static final Map<String, String> _modernNames = _buildModernNames();

  static Map<String, String> _buildModernNames() {
    final m = <String, String>{};
    for (final e in StructuredQueries.herbAliases.entries) {
      // putIfAbsent 保留首个现代名：牡桂 → 桂枝（而非后面的 肉桂）。
      m.putIfAbsent(e.value, () => e.key);
    }
    return m;
  }

  static String _herbDisplayName(String name) {
    final modern = _modernNames[name];
    return modern == null ? name : '$name（$modern）';
  }
}