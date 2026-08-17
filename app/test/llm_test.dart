// app/test/llm_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/llm/prompt_templates.dart';
import 'package:nihaixia_app/llm/llm_service.dart';
import 'package:nihaixia_app/llm/llm_runner.dart';

void main() {
  test('prompt 包含资料与要求', () {
    final p = PromptTemplates.rag(
      question: '桂枝汤什么时候用？',
      evidences: ['桂枝汤主太阳中风。'],
    );
    expect(p, contains('桂枝汤什么时候用'));
    expect(p, contains('仅基于以下资料'));
    expect(p, contains('桂枝汤主太阳中风'));
  });

  test('llm service 模型文件不存在时 isAvailable=false', () {
    final svc = LlmService(modelPath: '/nonexistent.gguf');
    expect(svc.isAvailable, false);
  });

  group('LlmGate 单飞闸门（Option A 拒绝式串行化）', () {
    test('第一个生成占用，第二个并发生成被拒绝', () {
      final gate = LlmGate();
      expect(gate.busy, isFalse);
      expect(gate.tryAcquire(), isTrue, reason: 'gen A 应先被准入');
      expect(gate.busy, isTrue);
      expect(gate.tryAcquire(), isFalse, reason: 'gen B 在 gen A 进行中应被拒绝');
    });

    test('release 后新的生成可再次准入', () {
      final gate = LlmGate();
      expect(gate.tryAcquire(), isTrue); // gen A
      gate.release(); // gen A 结束
      expect(gate.busy, isFalse);
      expect(gate.tryAcquire(), isTrue, reason: 'gen C 在闸门释放后应被准入');
    });

    test('release 幂等，重复释放不抛错', () {
      final gate = LlmGate();
      gate.tryAcquire();
      gate.release();
      gate.release();
      expect(gate.busy, isFalse);
      expect(gate.tryAcquire(), isTrue);
    });
  });
}
