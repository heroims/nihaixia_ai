import 'package:nihaixia_app/retrieval/qa_service.dart';

import 'diagnostic_engine.dart';

typedef DiagnosisAnswer = Future<QaResult> Function(
  String query, {
  String? retrievalQuery,
});

/// Result of one guided-diagnosis request: model/RAG answer plus the
/// deterministic rule hint used to make the evidence and fallback explicit.
class DiagnosisResponse {
  final String question;
  final String retrievalQuery;
  final QaResult qa;
  final DiagnosisResult ruleHint;

  const DiagnosisResponse({
    required this.question,
    required this.retrievalQuery,
    required this.qa,
    required this.ruleHint,
  });
}

class DiagnosisService {
  final QaService? qaService;
  final DiagnosisAnswer? answerOverride;

  const DiagnosisService({this.qaService, this.answerOverride});

  Future<DiagnosisResponse> diagnose(SymptomInput input) async {
    final ruleHint = DiagnosticEngine.evaluate(input);
    final retrievalQuery = buildRetrievalQuery(input);
    final question = buildQuestion(input, ruleHint: ruleHint);
    if (retrievalQuery.isEmpty) {
      return DiagnosisResponse(
        question: question,
        retrievalQuery: retrievalQuery,
        qa: const QaResult(
          hasAnswer: false,
          answer: '尚未提供足够症状，无法开始检索或模型分析。',
        ),
        ruleHint: ruleHint,
      );
    }

    final answer = answerOverride ?? qaService?.answer;
    if (answer == null) throw StateError('问答服务不可用');
    final qa = await answer(question, retrievalQuery: retrievalQuery);
    return DiagnosisResponse(
      question: question,
      retrievalQuery: retrievalQuery,
      qa: qa,
      ruleHint: ruleHint,
    );
  }

  static String buildRetrievalQuery(SymptomInput input) {
    final terms = <String>[];
    switch (input.cold) {
      case ColdState.aversionToCold:
        terms.add('怕冷');
      case ColdState.aversionToWind:
        terms.add('怕风');
      case ColdState.aversionToHeat:
        terms.add('怕热');
      case ColdState.unknown:
        break;
    }
    switch (input.sweat) {
      case SweatState.hasSweat:
        terms.add('有汗');
      case SweatState.noSweat:
        terms.add('无汗');
      case SweatState.unknown:
        break;
    }
    if (input.painNeck) terms.add('头项强痛');
    if (input.bodyAche) terms.add('身体酸痛');
    if (input.thirst) terms.add('口渴');
    if (input.fever) terms.add('发热');
    return terms.join(' ');
  }

  static String buildQuestion(
    SymptomInput input, {
    DiagnosisResult? ruleHint,
  }) {
    final hint = ruleHint ?? DiagnosticEngine.evaluate(input);
    final terms = buildRetrievalQuery(input);
    final hintText = switch (hint.status) {
      DiagnosisStatus.matched =>
        '规则基线提示：${hint.jing}，${hint.suggestedFormula}。',
      DiagnosisStatus.insufficient => '规则基线提示：症状信息仍然不足。',
      DiagnosisStatus.unmatched => '规则基线提示：当前组合未命中固定规则，请结合原文证据判断。',
    };
    return '引导式诊断症状摘要：$terms。\n'
        '$hintText\n'
        '请完整整合症状、知识库检索证据与规则基线，给出谨慎的辨证思路、'
        '可能的经典出处和下一步需要补充的信息。明确说明这不是医疗诊断，'
        '不要在证据不足时臆造方药。';
  }
}
