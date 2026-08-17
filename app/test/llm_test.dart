// app/test/llm_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/llm/prompt_templates.dart';
import 'package:nihaixia_app/llm/llm_service.dart';

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
}
