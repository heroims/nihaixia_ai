// app/integration_test/mode_switch_stress_test.dart
// 模式切换压力回归：复现并守住 iOS 模拟器闪退场景——
// 快速连续切换推理模式会反复「销毁旧推理 isolate → 创建新 isolate」，
// 旧代码在强杀时留下悬垂的全局 FFI 日志回调，原生侧打日志即 SIGSEGV。
// 运行：flutter test integration_test/mode_switch_stress_test.dart -d <device>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nihaixia_app/app.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/core/db_loader.dart';
import 'package:nihaixia_app/llm/inference_settings.dart';

// ignore_for_file: avoid_print

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('模式快速轮切不崩溃，轮切后提问有回答', (tester) async {
    AppDatabase? db;
    try {
      db = await DbLoader.loadFromAssets();
    } catch (_) {}
    await tester.pumpWidget(NihaixiaApp(database: db));
    await tester.pump(const Duration(seconds: 3));

    // 压力：3 轮全模式快切。每轮都触发问答页重新接线（dispose→create）。
    for (var round = 1; round <= 3; round++) {
      for (final m in InferenceMode.values) {
        print('[stress] round=$round setMode=${m.label}');
        await InferenceSettings.instance.setMode(m);
        await tester.pump(const Duration(milliseconds: 200));
      }
    }
    // 留时间给最后一次接线的预热加载完成（iOS ~1.6s / Android ~16s）。
    await tester.pump(const Duration(seconds: 20));

    // 轮切后真实提问：云端优先模式下若云端可用走云端，否则落端侧/检索，
    // 任一通道出回答即通过（来源标签 chip 可见）。
    final input = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.hintText == '问倪海厦经方…');
    expect(input, findsOneWidget);
    await tester.enterText(input, '当归有什么功效');
    await tester.tap(find.widgetWithText(FilledButton, '问'));

    final deadline = DateTime.now().add(const Duration(minutes: 8));
    var answered = false;
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(seconds: 5));
      if (find.text('云端模型').evaluate().isNotEmpty ||
          find.text('端侧模型').evaluate().isNotEmpty ||
          find.text('知识库原文').evaluate().isNotEmpty) {
        answered = true;
        break;
      }
    }
    expect(answered, isTrue, reason: '模式轮切后提问应得到任一通道的回答');
    // 流式解码回归：回答文本不得出现 U+FFFD（跨 token 拆分的中文字符
    // 曾被错误冲掉显示为「�」）。
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('\uFFFD'), findsNothing,
        reason: '回答文本不应包含乱码替换字符');
  }, timeout: const Timeout(Duration(minutes: 18)));
}
