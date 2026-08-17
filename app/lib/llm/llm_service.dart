// app/lib/llm/llm_service.dart
import 'dart:io';

/// llama_cpp_dart 轻封装，对外契约：isAvailable + generate。
/// Task 20 已提供基于 LlamaParent（隔离岛）的真实实现，此处仅留接口，
/// 避免同一文件出现两套实现。
class LlmService {
  final String modelPath;
  final int ctxSize;
  bool _failed = false;

  LlmService({required this.modelPath, this.ctxSize = 2048});

  bool get isAvailable => !_failed && File(modelPath).existsSync();

  /// 同步返回可用状态（测试用）。
  void markUnavailable() => _failed = true;

  /// 真实实现见 Task 20；这里保持契约存在返回 null。
  Future<String?> generate(String prompt) async {
    if (!isAvailable) return null;
    throw UnimplementedError('真实推理在 Task 20 落位');
  }
}
