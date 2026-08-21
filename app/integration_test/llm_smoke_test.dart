// app/integration_test/llm_smoke_test.dart
// 端侧 LLM 冒烟测试：在真机/模拟器上验证「资产复制 → 模型加载 → 生成」全链路。
// 运行：flutter test integration_test/llm_smoke_test.dart -d <device>
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nihaixia_app/llm/llm_service.dart';
import 'package:nihaixia_app/llm/model_resolver.dart';

// ignore_for_file: avoid_print
typedef _LogNative = ffi.Void Function(
    ffi.Int32, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Void>);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('端侧模型复制、加载并生成', (tester) async {
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

    await svc.dispose();
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// 挂到 llama_log_set 的原生日志回调（在 LlmService 加载前由测试接线）。
void installLlamaLogBridge() {
  final lib = ffi.DynamicLibrary.open('libllama.so');
  final setLog =
      lib.lookupFunction<ffi.Void Function(ffi.Pointer<ffi.NativeFunction<_LogNative>>), void Function(ffi.Pointer<ffi.NativeFunction<_LogNative>>)>('llama_log_set');
  final cb = ffi.Pointer.fromFunction<_LogNative>(_onLog);
  setLog(cb);
}

void _onLog(int level, ffi.Pointer<ffi.Char> text, ffi.Pointer<ffi.Void> _) {
  final bytes = <int>[];
  var i = 0;
  while (true) {
    final b = text[i++];
    if (b == 0) break;
    bytes.add(b);
  }
  final msg = utf8.decode(bytes, allowMalformed: true).trim();
  if (msg.isNotEmpty) print('[llama.cpp] $msg');
}
