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
  bool _loaded = false;
  String? _loadError;

  LlmService({required this.modelPath, this.ctxSize = 4096});

  /// 一次性降级语义：加载失败后保持不可用，不再每次重试。
  bool get isAvailable => !_failed && File(modelPath).existsSync();

  /// 模型是否已真正加载进 llama.cpp（区别于文件存在性检查）。
  bool get isLoaded => _loaded;

  /// 最近一次加载失败的原因（未失败为 null）。
  String? get loadError => _loadError;

  /// 同步标记不可用（测试/预热用）。
  void markUnavailable() => _failed = true;

  /// 显式预加载：把模型载入 llama.cpp 并返回是否成功。
  /// 失败原因记录在 [loadError]，并按一次性降级语义标记不可用。
  Future<bool> preload() async {
    if (!isAvailable) {
      _loadError = _failed ? (_loadError ?? '此前加载失败') : '模型文件不存在';
      return false;
    }
    try {
      _runner ??= LlmRunner();
      await _runner!.ensureLoaded(modelPath: modelPath, nCtx: ctxSize);
      _loaded = true;
      _loadError = null;
      return true;
    } catch (e) {
      debugPrint('[LLM] preload: ERROR $e, mark failed');
      _loadError = e.toString();
      final r = _runner;
      _runner = null;
      await r?.dispose();
      _failed = true;
      return false;
    }
  }

  Future<String?> generate(String prompt) async {
    if (!isAvailable) {
      debugPrint('[LLM] generate: NOT available (failed=$_failed exists=${File(modelPath).existsSync()}), return null');
      return null;
    }
    try {
      _runner ??= LlmRunner();
      await _runner!.ensureLoaded(modelPath: modelPath, nCtx: ctxSize);
      _loaded = true;
      debugPrint('[LLM] generate: calling runner, promptLen=${prompt.length}');
      final out = await _runner!.generate(prompt);
      debugPrint('[LLM] generate: runner returned outLen=${out.length}');
      return out;
    } catch (e) {
      debugPrint('[LLM] generate: ERROR $e, mark failed');
      _loadError = e.toString();
      final r = _runner;
      _runner = null;
      await r?.dispose();
      _failed = true;
      return null;
    }
  }

  Future<void> dispose() async {
    final r = _runner;
    _runner = null;
    await r?.dispose();
  }
}
