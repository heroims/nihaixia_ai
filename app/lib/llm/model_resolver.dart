// app/lib/llm/model_resolver.dart
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 端侧 LLM 模型文件定位，按序：
/// 1. 应用支持目录已存在模型文件（历史复制/手动部署）→ 直接使用；
/// 2. assets 打包了模型（assets/models/*.gguf 注册进 pubspec 后）→ 首次复制
///    到应用支持目录，此后走第 1 条；
/// 3. 均不可用 → null（App 降级纯检索，LlmService.isAvailable 二次把关）。
///
/// 先查本地文件再读 assets：避免每次启动都做 1.1GB 的 rootBundle 读取
/// （assets 存在且文件已在本地时，本地即权威副本）。
class LlmModelResolver {
  static const modelFileName = 'qwen3-1.7b-instruct-q4_k_m.gguf';
  static const assetPath = 'assets/models/$modelFileName';

  /// [overrideDir] 仅供测试注入（path_provider 在 flutter test 无插件通道）。
  static Future<String?> resolve({Directory? overrideDir}) async {
    final dir = overrideDir ?? await getApplicationSupportDirectory();
    final local = p.join(dir.path, modelFileName);
    if (File(local).existsSync()) return local;
    try {
      final data = await rootBundle.load(assetPath);
      File(local).parent.createSync(recursive: true);
      await File(local).writeAsBytes(data.buffer.asUint8List(), flush: true);
      return local;
    } catch (_) {
      return null;
    }
  }
}