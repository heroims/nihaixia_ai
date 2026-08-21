// app/lib/llm/rag_synthesizer.dart
import 'package:flutter/foundation.dart';
import 'prompt_templates.dart';
import 'llm_service.dart';

class RagSynthesizer {
  final LlmService llm;
  RagSynthesizer(this.llm);

  bool get enabled {
    final e = llm.isAvailable;
    debugPrint('[RAG] enabled=$e (model exists & not failed)');
    return e;
  }

  Future<String?> synthesize({
    required String question,
    required List<String> evidences,
  }) async {
    debugPrint('[RAG] synthesize: start, questionLen=${question.length} evidences=${evidences.length}');
    if (!enabled) {
      debugPrint('[RAG] synthesize: disabled, return null');
      return null;
    }
    final prompt = PromptTemplates.rag(question: question, evidences: evidences);
    final out = await llm.generate(prompt);
    debugPrint('[RAG] synthesize: llm.generate returned outLen=${out?.length}');
    // Qwen3 默认输出 <think>…</think> 推理块，正文在其后；剥离后才是给用户的回答。
    final answer = _stripThink(out ?? '');
    // 空/空白输出视为不可用（Task 19 Important #2）：LLM 可能只回换行/占位符，
    // 或生成被截断在思考块内（剥离后为空），QaService 据此走检索原文降级，
    // 不让空串冒充回答。
    if (answer.trim().isEmpty) {
      debugPrint('[RAG] synthesize: empty output after strip, return null (degrade)');
      return null;
    }
    debugPrint('[RAG] synthesize: done, output=${answer.trim().substring(0, answer.trim().length > 40 ? 40 : answer.trim().length)}...');
    return answer;
  }

  /// 剥离 Qwen3 的思考块：完整 `<think>…</think>` 整段移除；
  /// 只有 `<think>` 没有闭合（生成被超时截断在推理阶段）时同样整段移除，
  /// 剩下的正文（若有）作为回答返回。
  static String _stripThink(String s) {
    var t = s.replaceFirst(RegExp(r'<think>[\s\S]*?</think>'), '');
    final open = t.indexOf('<think>');
    if (open != -1) t = t.substring(0, open);
    return t.trim();
  }
}
