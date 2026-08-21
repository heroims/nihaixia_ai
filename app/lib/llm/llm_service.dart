// app/lib/llm/llm_service.dart
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'llm_runner.dart';

/// llama_cpp_dart 真实推理封装，对外契约：isAvailable + generate。
/// 模型文件缺失、加载失败、推理异常任一情况，generate 返回 null（降级），
/// App 永不因为 LLM 不可用而崩溃。
class LlmService {
  final String modelPath;
  final int ctxSize;
  LlmRunner? _runner;
  bool _failed = false;

  LlmService({required this.modelPath, this.ctxSize = 4096});

  /// 一次性降级语义：加载失败后保持不可用，不再每次重试。
  bool get isAvailable => !_failed && File(modelPath).existsSync();

  /// 同步标记不可用（测试/预热用）。
  void markUnavailable() => _failed = true;

  Future<String?> generate(String prompt) async {
    if (!isAvailable) {
      debugPrint('[LLM] generate: NOT available (failed=$_failed exists=${File(modelPath).existsSync()}), return null');
      return null;
    }
    try {
      _runner ??= LlmRunner();
      await _runner!.ensureLoaded(modelPath: modelPath, nCtx: ctxSize);
      debugPrint('[LLM] generate: calling runner, promptLen=${prompt.length}');
      final out = await _runner!.generate(prompt);
      debugPrint('[LLM] generate: runner returned outLen=${out.length}');
      return out;
    } catch (e) {
      debugPrint('[LLM] generate: ERROR $e, mark failed');
      _runner?.dispose();
      _runner = null;
      _failed = true;
      return null;
    }
  }

  Future<void> dispose() async {
    _runner?.dispose();
    _runner = null;
  }
}
