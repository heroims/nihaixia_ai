// app/lib/llm/inference_settings.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 问答推理模式：
/// - [retrievalOnly] 纯检索：不加载任何 LLM，直接拼接命中的原文（无需模型）。
/// - [localLlm] 端侧模型：仅用本地 llama.cpp 合成，离线可用。
/// - [cloudFirst] 云端优先：配置了 OpenAI 兼容 API 时走云端，
///   失败/未配置落回端侧；端侧也不可用则降级纯检索。
enum InferenceMode { retrievalOnly, localLlm, cloudFirst }

extension InferenceModeLabel on InferenceMode {
  String get label => switch (this) {
        InferenceMode.retrievalOnly => '纯检索',
        InferenceMode.localLlm => '端侧模型',
        InferenceMode.cloudFirst => '云端优先',
      };
}

/// 推理模式的全局状态：设置页写入，问答页监听并即时重新接线。
/// 单例足够（App 内只有一处消费方），避免引入状态管理框架。
class InferenceSettings extends ChangeNotifier {
  InferenceSettings._();

  static final InferenceSettings instance = InferenceSettings._();

  static const _prefKey = 'inference_mode';
  static const _default = InferenceMode.cloudFirst;

  InferenceMode _mode = _default;
  bool _loaded = false;

  InferenceMode get mode => _mode;

  /// 启动时恢复持久化的模式；非法值回退默认。
  Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final idx = p.getInt(_prefKey);
    _mode = (idx == null || idx < 0 || idx >= InferenceMode.values.length)
        ? _default
        : InferenceMode.values[idx];
    _loaded = true;
  }

  Future<void> setMode(InferenceMode m) async {
    if (m == _mode) return;
    _mode = m;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_prefKey, m.index);
    notifyListeners();
  }

  /// 测试注入点：单例跨测试共享，直接重置内部状态。
  @visibleForTesting
  void setModeForTest(InferenceMode m, {bool markUnloaded = false}) {
    _mode = m;
    if (markUnloaded) _loaded = false;
  }
}
