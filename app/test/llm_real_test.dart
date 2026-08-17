// app/test/llm_real_test.dart
@Tags(['real'])
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/llm/llm_service.dart';

void main() {
  test('real model generates', () async {
    const modelPath = 'assets/models/qwen3-1.7b-instruct-q4_k_m.gguf';
    final llm = LlmService(modelPath: modelPath);
    expect(llm.isAvailable, true);
    final out = await llm.generate('请回答：1+1等于几？');
    expect(out, isNotNull);
    expect(out, contains('2'));
  }, tags: ['real']);
}
