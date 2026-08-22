import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/models.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'package:nihaixia_app/rules/diagnosis_service.dart';
import 'package:nihaixia_app/rules/diagnostic_engine.dart';

void main() {
  test('诊断服务保留完整问题并生成稳定检索词', () async {
    String? prompt;
    String? retrieval;
    final service = DiagnosisService(
      answerOverride: (query, {retrievalQuery}) async {
        prompt = query;
        retrieval = retrievalQuery;
        return const QaResult(hasAnswer: true, answer: '检索结论');
      },
    );

    final response = await service.diagnose(const SymptomInput(
      sweat: SweatState.noSweat,
      cold: ColdState.aversionToCold,
      bodyAche: true,
      thirst: true,
    ));

    expect(response.ruleHint.status, DiagnosisStatus.matched);
    expect(retrieval, '怕冷 无汗 身体酸痛 口渴');
    expect(prompt, contains('引导式诊断症状摘要'));
    expect(prompt, contains('完整整合'));
    expect(prompt, isNot(contains('【问题】怕冷 无汗')));
  });

  test('没有症状时不发起问答请求', () async {
    var called = false;
    final service = DiagnosisService(
      answerOverride: (_, {retrievalQuery}) async {
        called = true;
        return const QaResult(hasAnswer: false);
      },
    );

    final response = await service.diagnose(const SymptomInput());
    expect(called, isFalse);
    expect(response.qa.hasAnswer, isFalse);
    expect(response.ruleHint.status, DiagnosisStatus.insufficient);
  });
}
