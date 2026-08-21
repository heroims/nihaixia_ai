// app/lib/llm/rag_synthesizer.dart
import 'package:flutter/foundation.dart';
import 'package:nihaixia_app/cloud/cloud_client.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
import 'prompt_templates.dart';
import 'llm_service.dart';

/// 合成结果元数据：回答文本 + 实际使用的通道 + 备注（如云端失败原因）。
class SynthResult {
  /// 回答正文（已剥离思考块）。
  final String text;

  /// 实际通道：'cloud' | 'local'。
  final String channel;

  /// 补充说明：云端失败回落端侧时携带失败原因；正常时为 null。
  final String? note;

  const SynthResult(this.text, this.channel, {this.note});
}

/// RAG 合成器：把检索证据交给 LLM 归纳成回答。
///
/// 生成通道优先级：云端（OpenAI 兼容 chat）→ 端侧 llama.cpp。
/// 任一通道失败自动落到下一通道；全部失败返回 null，
/// QaService 据此降级为检索原文。通道选择与失败原因经 [SynthResult.note]
/// 上传，UI 可标注「本回答来自云端/端侧」。
class RagSynthesizer {
  final LlmService? llm;
  final CloudConfig? cloud;

  /// 每次提问时实时获取云端配置（设置保存后立即生效，无需重启）。
  /// 与 [cloud] 同时提供时优先使用本回调。
  final Future<CloudConfig?> Function()? _cloudProvider;

  /// 测试注入点：替换 [CloudClient.chat]；生产代码不传。
  final Future<String> Function(CloudConfig, List<Map<String, String>>)? _chatOverride;

  RagSynthesizer(
    this.llm, {
    this.cloud,
    Future<CloudConfig?> Function()? cloudProvider,
    Future<String> Function(CloudConfig, List<Map<String, String>>)? chatOverride,
  })  : _cloudProvider = cloudProvider,
        _chatOverride = chatOverride;

  /// 是否有可用回答通道。云端按「配置齐全」判断——是否启用云端由推理
  /// 模式在接线时决定（非云端优先模式根本不会传入 cloud/cloudProvider），
  /// 避免与遗留 enabled 开关形成两套矛盾的状态源。
  bool get enabled =>
      (cloud?.isConfigured ?? false) || (llm?.isAvailable ?? false);

  Future<SynthResult?> synthesize({
    required String question,
    required List<String> evidences,
  }) async {
    debugPrint('[RAG] synthesize: start, questionLen=${question.length} evidences=${evidences.length}');
    final local = llm;
    // 云端配置每次提问时实时读取，设置页保存后立即生效。
    final cfg = await (_cloudProvider?.call() ?? Future.value(cloud));
    if ((cfg?.isConfigured ?? false) == false && (local == null || !local.isAvailable)) {
      debugPrint('[RAG] synthesize: no channel available, return null');
      return null;
    }
    final prompt = _buildPromptWithinBudget(question, evidences);

    // 云端优先：快且质量高；失败不阻断，落回端侧（原因记入 note 供 UI 展示）。
    // 能走到这里说明接线时已处于云端优先模式，此处只看配置是否齐全。
    String? cloudError;
    if (cfg != null && cfg.isConfigured) {
      try {
        debugPrint('[RAG] using cloud (${cfg.defaultModel})');
        final chat = _chatOverride ?? CloudClient.chat;
        final out = await chat(cfg, [
          {'role': 'user', 'content': prompt},
        ]);
        final answer = stripThink(out);
        if (answer.isNotEmpty) {
          debugPrint('[RAG] synthesize: done via cloud, output=${_preview(answer)}');
          return SynthResult(answer, 'cloud');
        }
        cloudError = '云端返回空内容';
        debugPrint('[RAG] $cloudError after strip, fallback to local');
      } catch (e) {
        cloudError = e.toString();
        debugPrint('[RAG] cloud failed, fallback to local: $e');
      }
    }

    // 端侧通道。
    if (local == null || !local.isAvailable) {
      debugPrint('[RAG] no local llm available, return null (degrade)');
      return null;
    }
    final out = await local.generate(prompt);
    debugPrint('[RAG] synthesize: llm.generate returned outLen=${out?.length}');
    // Qwen3 默认输出 <think>…</think> 推理块，正文在其后；剥离后才是给用户的回答。
    final answer = stripThink(out ?? '');
    // 空/空白输出视为不可用（Task 19 Important #2）：LLM 可能只回换行/占位符，
    // 或生成被截断在思考块内（剥离后为空），QaService 据此走检索原文降级，
    // 不让空串冒充回答。
    if (answer.isEmpty) {
      debugPrint('[RAG] synthesize: empty output after strip, return null (degrade)');
      return null;
    }
    debugPrint('[RAG] synthesize: done, output=${_preview(answer)}');
    return SynthResult(answer, 'local', note: cloudError == null ? null : '$cloudError，已用端侧模型回答');
  }

  static String _preview(String s) {
    final t = s.trim();
    return t.length > 40 ? '${t.substring(0, 40)}...' : t;
  }

  /// 提示词上下文预算：nCtx=4096 token，按中文最坏 1 字/token 估算，
  /// 留 ≥1000 token 生成余量 → 上限 3000 字符。超长 prompt 会写爆按
  /// nCtx 分配的 batch 缓冲区导致原生崩溃（包内已补硬校验兜底）。
  static const _maxPromptChars = 3000;

  /// 组提示词并控制在预算内：先丢尾部证据（相关性递减，最少保 3 条），
  /// 仍超限则硬剪。保证端侧/云端都拿到合法长度的输入。
  static String _buildPromptWithinBudget(
      String question, List<String> evidences) {
    var evs = evidences.take(8).toList();
    var prompt = PromptTemplates.rag(question: question, evidences: evs);
    while (prompt.length > _maxPromptChars && evs.length > 3) {
      evs = evs.sublist(0, evs.length - 1);
      prompt = PromptTemplates.rag(question: question, evidences: evs);
    }
    if (prompt.length > _maxPromptChars) {
      prompt = prompt.substring(0, _maxPromptChars);
    }
    return prompt;
  }

  /// 剥离 Qwen3 的思考块：完整 `<think>…</think>` 整段移除；
  /// 只有 `<think>` 没有闭合（生成被超时截断在推理阶段）时同样整段移除，
  /// 剩下的正文（若有）作为回答返回。
  static String stripThink(String s) {
    var t = s.replaceFirst(RegExp(r'<think>[\s\S]*?</think>'), '');
    final open = t.indexOf('<think>');
    if (open != -1) t = t.substring(0, open);
    return t.trim();
  }
}
