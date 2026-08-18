// app/test/model_resolver_test.dart
import 'dart:io';

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

  test('overrideDir 无模型且 assets 未注册时返回 null', () async {
    final dir = await Directory.systemTemp.createTemp('model_resolver_test');
    addTearDown(() => dir.delete(recursive: true));

    // assets/models/ 未注册进 pubspec.yaml，rootBundle.load 必然抛错 → null。
    final path = await LlmModelResolver.resolve(overrideDir: dir);

    expect(path, isNull);
  });
}