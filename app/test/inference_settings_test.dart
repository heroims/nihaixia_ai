// app/test/inference_settings_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nihaixia_app/llm/inference_settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // 单例跨测试共享，重置内部状态。
    InferenceSettings.instance.setModeForTest(InferenceMode.cloudFirst);
  });

  test('默认模式为云端优先', () async {
    await InferenceSettings.instance.load();
    expect(InferenceSettings.instance.mode, InferenceMode.cloudFirst);
  });

  test('setMode 持久化并在 load 后恢复', () async {
    final s = InferenceSettings.instance;
    await s.setMode(InferenceMode.retrievalOnly);
    expect(s.mode, InferenceMode.retrievalOnly);

    // 模拟重启：重置后重新加载。
    s.setModeForTest(InferenceMode.cloudFirst);
    await s.load();
    expect(s.mode, InferenceMode.retrievalOnly);
  });

  test('持久化了非法索引时回退默认模式', () async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('inference_mode', 999);
    await InferenceSettings.instance.load();
    expect(InferenceSettings.instance.mode, InferenceMode.cloudFirst);
  });

  test('setMode 触发 notifyListeners（问答页据此重新接线）', () async {
    var notified = 0;
    void listener() => notified++;
    final s = InferenceSettings.instance;
    s.addListener(listener);
    await s.setMode(InferenceMode.localLlm);
    s.removeListener(listener);
    expect(notified, 1);
  });

  test('重复设置相同模式不触发通知', () async {
    var notified = 0;
    void listener() => notified++;
    final s = InferenceSettings.instance;
    s.addListener(listener);
    await s.setMode(s.mode);
    s.removeListener(listener);
    expect(notified, 0);
  });
}
