// app/lib/llm/model_resolver.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 端侧 LLM 模型文件定位，按序：
/// 1. 应用支持目录已存在模型文件（历史复制/手动部署）→ 直接使用；
/// 2. assets 打包了模型（assets/models/*.gguf 注册进 pubspec 后）→ 首次复制
///    到应用支持目录，此后走第 1 条；
/// 3. 均不可用 → null（App 降级纯检索，LlmService.isAvailable 二次把关）。
///
/// Android 特例：rootBundle.load 单块 TypedData 上限 2^30-1 字节（约 1GB），
/// 1.1GB 模型必然抛 NewExternalTypedData 错误，故改走 MethodChannel 在原生侧
/// 分块流式复制（内存占用恒定）。其余平台维持 rootBundle 路径。
///
/// 先查本地文件再复制：避免每次启动都做 1.1GB 的重复拷贝
/// （assets 存在且文件已在本地时，本地即权威副本）。
class LlmModelResolver {
  static const modelFileName = 'Qwen3.5-0.8B-Q6_K.gguf';
  static const assetPath = 'assets/models/$modelFileName';

  /// 设置页展示用的模型名（不含扩展名）。
  static String get modelDisplayName =>
      modelFileName.replaceAll(RegExp(r'\.gguf$'), '');

  static const _installChannel = MethodChannel('model_installer');

  /// 端侧模型是否已安装到应用支持目录（设置页状态展示用）。
  static Future<bool> isInstalled({Directory? overrideDir}) async {
    final dir = overrideDir ?? await getApplicationSupportDirectory();
    return File(p.join(dir.path, modelFileName)).existsSync();
  }

  /// 测试注入点：flutter test 跑在宿主机上 Platform.isAndroid 恒为 false，
  /// 无法覆盖平台通道分支；置 true 强制走 Android 复制路径。
  @visibleForTesting
  static bool? forceAndroidPathForTest;

  /// [overrideDir] 仅供测试注入（path_provider 在 flutter test 无插件通道）。
  static Future<String?> resolve({Directory? overrideDir}) async {
    final dir = overrideDir ?? await getApplicationSupportDirectory();
    final local = p.join(dir.path, modelFileName);
    if (File(local).existsSync()) return local;
    if (forceAndroidPathForTest ?? Platform.isAndroid) {
      final copied = await _copyViaPlatformChannel(local);
      if (!copied) return null;
      return File(local).existsSync() ? local : null;
    }
    try {
      final data = await rootBundle.load(assetPath);
      File(local).parent.createSync(recursive: true);
      await File(local).writeAsBytes(data.buffer.asUint8List(), flush: true);
      return local;
    } catch (_) {
      return null;
    }
  }

  /// Android：经原生通道把 APK 内资产分块复制到 [dest]。
  /// 通道不可用/复制失败一律返回 false（降级纯检索，不崩溃）。
  static Future<bool> _copyViaPlatformChannel(String dest) async {
    try {
      debugPrint('[ModelResolver] copying model via platform channel...');
      final sw = Stopwatch()..start();
      final ok = await _installChannel.invokeMethod<bool>('copyAssetToFile', {
        'asset': assetPath,
        'dest': dest,
      });
      debugPrint('[ModelResolver] copy done ok=$ok in ${sw.elapsedMilliseconds}ms');
      return ok == true;
    } catch (e) {
      debugPrint('[ModelResolver] platform copy failed: $e');
      return false;
    }
  }
}
