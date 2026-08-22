// app/lib/llm/local_model_state.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'model_resolver.dart';

/// 端侧模型生命周期阶段（设置页状态展示 + 问答页预热上报）。
enum LocalModelPhase {
  /// 尚未检查。
  checking,

  /// 支持目录中没有模型文件。
  notInstalled,

  /// 文件在但未加载进 llama.cpp。
  installedNotLoaded,

  /// 加载中（628MB 模型约需数秒）。
  loading,

  /// 已加载，可离线推理。
  loaded,

  /// 加载失败，[detail] 携带原因。
  failed,
}

/// 端侧模型加载状态的全局单例：问答页接线时驱动，设置页监听展示。
/// 与 [InferenceSettings] 同理用单例避免引入状态管理框架。
class LocalModelState extends ChangeNotifier {
  LocalModelState._();

  static final LocalModelState instance = LocalModelState._();

  LocalModelPhase _phase = LocalModelPhase.checking;
  String? _detail;

  LocalModelPhase get phase => _phase;
  String? get detail => _detail;

  bool get isReady => _phase == LocalModelPhase.loaded;

  /// 按文件存在性刷新（不触发真正的 llama.cpp 加载）。
  Future<void> refreshInstalled({Directory? overrideDir}) async {
    final installed = await LlmModelResolver.isInstalled(overrideDir: overrideDir);
    _set(installed ? LocalModelPhase.installedNotLoaded : LocalModelPhase.notInstalled);
  }

  void reportLoading() => _set(LocalModelPhase.loading);

  void reportLoaded() {
    _detail = null;
    _set(LocalModelPhase.loaded);
  }

  void reportFailed(String detail) => _set(LocalModelPhase.failed, detail: detail);

  void _set(LocalModelPhase p, {String? detail}) {
    _detail = detail;
    if (_phase == p && detail == null) return;
    _phase = p;
    notifyListeners();
  }
}
