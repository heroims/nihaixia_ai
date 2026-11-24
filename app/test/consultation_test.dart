import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
import 'package:nihaixia_app/llm/rag_synthesizer.dart';
import 'package:nihaixia_app/retrieval/consultation_session.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'package:nihaixia_app/core/models.dart';

void main() {
  const cfg = CloudConfig(baseUrl: 'https://example.com', apiKey: 'k');
  test('动态云端单独接入可用', () {
    expect(RagSynthesizer(null, cloudProvider: () async => cfg).enabled, true);
  });
  test('检索追问并确认后输出，保留历史证据', () async {
    final prompts = <String>[];
    final outputs = [
      '{"action":"search","query":"恶寒"}',
      '{"action":"ask","text":"持续多久？"}',
      '{"action":"confirm","text":"怕冷两天，请核对。"}',
      '{"action":"final","text":"仅供参考的分析"}',
    ];
    final session = ConsultationSession(
      synthesize: (prompt) async {
        prompts.add(prompt);
        return SynthResult(outputs.removeAt(0), 'cloud');
      },
      retrieve: (q) async => const QaResult(hasAnswer: true, sources: [
        SearchHit(source: '伤寒论', heading: '条文', text: '恶寒'),
      ]),
    );
    await session.send('我怕冷');
    expect(session.messages.last.text, '持续多久？');
    await session.send('两天');
    expect(session.stage, ConsultationStage.confirming);
    await session.send('确认', confirmed: true);
    expect(session.stage, ConsultationStage.complete);
    expect(prompts.last, contains('我怕冷'));
    expect(prompts.last, contains('恶寒'));
    expect(session.messages.last.sources, hasLength(1));
  });
  test('模型提前结束被拦截', () async {
    final session = ConsultationSession(
      synthesize: (_) async =>
          const SynthResult('{"action":"final","text":"结论"}', 'cloud'),
      retrieve: (_) async => const QaResult(hasAnswer: false),
    );
    await session.send('不舒服');
    expect(session.stage, isNot(ConsultationStage.complete));
    expect(session.messages.last.text, isNot('结论'));
  });
  test('知识问题直接回答且不要求确认', () async {
    final session = ConsultationSession(
      synthesize: (_) async =>
          const SynthResult('{"action":"knowledge","text":"查询"}', 'cloud'),
      retrieve: (_) async => const QaResult(hasAnswer: false),
      answerKnowledge: (_) async =>
          const QaResult(hasAnswer: true, answer: '方剂资料', channel: 'cloud'),
    );
    await session.send('桂枝汤是什么');
    expect(session.messages.last.text, '方剂资料');
    expect(session.stage, ConsultationStage.collecting);
  });
  test('连续检索有上限，无命中反馈给下一次模型', () async {
    var calls = 0;
    var lastPrompt = '';
    final session = ConsultationSession(
      synthesize: (prompt) async {
        calls++;
        lastPrompt = prompt;
        return const SynthResult('{"action":"search","query":"恶寒"}', 'cloud');
      },
      retrieve: (_) async => const QaResult(hasAnswer: false),
    );
    await session.send('怕冷');
    expect(calls, 4);
    expect(lastPrompt, contains('未找到依据'));
    expect(session.messages.last.text, contains('重试'));
  });
  test('用户纠正后必须重新确认', () async {
    var calls = 0;
    final session = ConsultationSession(
      synthesize: (_) async => SynthResult(
          calls++ == 0
              ? '{"action":"confirm","text":"请核对"}'
              : '{"action":"final","text":"提前结论"}',
          'cloud'),
      retrieve: (_) async => const QaResult(hasAnswer: false),
    );
    await session.send('头痛');
    await session.send('其实是腹痛');
    expect(session.stage, ConsultationStage.collecting);
    expect(session.messages.last.text, isNot('提前结论'));
  });
  test('异常保留对话并可重试', () async {
    final session = ConsultationSession(
      synthesize: (_) async => throw Exception('offline'),
      retrieve: (_) async => const QaResult(hasAnswer: false),
    );
    await session.send('头痛');
    expect(session.messages.first.text, '头痛');
    expect(session.messages.last.text, contains('重试'));
  });
}
