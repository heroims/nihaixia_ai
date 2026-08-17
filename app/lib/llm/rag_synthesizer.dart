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
    return llm.generate(prompt);
  }
}
