// app/integration_test/llm_smoke_test.dart
// 端侧 LLM 冒烟测试：在真机/模拟器上验证「资产复制 → 模型加载 → 生成 →
// 优雅销毁 → 重建再生成」全链路。销毁重建循环回归全局日志回调竞态
// （isolate 强杀留悬垂 FFI 回调，原生打日志即 SIGSEGV，iOS 模拟器实测）。
// 运行：flutter test integration_test/llm_smoke_test.dart -d <device>
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nihaixia_app/llm/llm_service.dart';
import 'package:nihaixia_app/llm/model_resolver.dart';

// ignore_for_file: avoid_print

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('端侧模型复制、加载、生成并安全重建', (tester) async {
    final path = await LlmModelResolver.resolve();
    print('[smoke] model path=$path');
    expect(path, isNotNull, reason: '模型应从 APK 资产成功复制到应用目录');

    final f = File(path!);
    print('[smoke] size=${f.lengthSync()}');
    print('[smoke] head=${f.openSync().readSync(4)}');

    final svc = LlmService(modelPath: path);
    expect(svc.isAvailable, isTrue);

    final out = await svc.generate('用一句话介绍你自己');
    print('[smoke] output=${out ?? "<null>"}');
    expect(out, isNotNull, reason: '端侧生成不应失败');
    expect(out!.trim(), isNotEmpty);

    // 优雅销毁：复位全局日志回调 + 释放原生上下文后再杀 isolate。
    await svc.dispose();

    // 销毁→重建循环：新 isolate 重新注册日志回调并再次加载生成。
    final svc2 = LlmService(modelPath: path);
    expect(svc2.isAvailable, isTrue);
    final out2 = await svc2.generate('再来一句');
    print('[smoke] reload output=${out2 ?? "<null>"}');
    expect(out2, isNotNull, reason: '销毁后重建的端侧生成不应失败');
    expect(out2!.trim(), isNotEmpty);
    await svc2.dispose();
  }, timeout: const Timeout(Duration(minutes: 20)));
}
