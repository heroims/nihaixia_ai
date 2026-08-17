// app/lib/llm/rag_synthesizer.dart
import 'prompt_templates.dart';
import 'llm_service.dart';

class RagSynthesizer {
  final LlmService llm;
  RagSynthesizer(this.llm);

  bool get enabled => llm.isAvailable;

  Future<String?> synthesize({
    required String question,
    required List<String> evidences,
  }) async {
    if (!enabled) return null;
    final prompt = PromptTemplates.rag(question: question, evidences: evidences);
    final out = await llm.generate(prompt);
    // 空/空白输出视为不可用（Task 19 Important #2）：LLM 可能只回换行/占位符，
    // QaService 据此走检索原文降级，不让空串冒充回答。
    if (out == null || out.trim().isEmpty) return null;
    return out;
  }
}
