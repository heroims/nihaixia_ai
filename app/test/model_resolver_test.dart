// app/test/model_resolver_test.dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/llm/model_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('overrideDir 中已有模型文件时直接返回该路径', () async {
    final dir = await Directory.systemTemp.createTemp('model_resolver_test');
    addTearDown(() => dir.delete(recursive: true));
    final f = File('${dir.path}/${LlmModelResolver.modelFileName}');
    f.writeAsBytesSync([1, 2, 3]);

    final path = await LlmModelResolver.resolve(overrideDir: dir);

    expect(path, f.path);
  });

  test('overrideDir 无模型但 assets 已注册时从 assets 复制并返回路径', () async {
    final dir = await Directory.systemTemp.createTemp('model_resolver_test');
    addTearDown(() => dir.delete(recursive: true));

    // assets/models 已注册进 pubspec.yaml；用 3 字节假模型模拟 asset 内容，
    // 避免在单测里加载 1.1GB 真实 GGUF。
    const fakeBytes = [1, 2, 3];
    final fake = ByteData.view(Uint8List.fromList(fakeBytes).buffer);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async => fake);
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance
        .defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null));

    final path = await LlmModelResolver.resolve(overrideDir: dir);

    expect(path, isNotNull);
    expect(
      File(path!).readAsBytesSync(),
      fakeBytes,
      reason: '应从 assets 复制模型内容到应用支持目录',
    );
  });
}