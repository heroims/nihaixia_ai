import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';

import 'inference_settings.dart';
import 'llm_service.dart';
import 'local_model_state.dart';
import 'model_resolver.dart';
import 'rag_synthesizer.dart';

/// App-wide inference wiring shared by the QA and guided-diagnosis surfaces.
///
/// The retrieval service is available immediately. Model/cloud wiring happens
/// asynchronously and keeps retrieval as a safe fallback while it is loading.
class InferenceSession extends ChangeNotifier {
  final AppDatabase? db;

  QaService? _service;
  LlmService? _llm;
  bool _synthesisWired = false;
  int _generation = 0;
  bool _disposed = false;
  bool _notifierDisposed = false;
  Future<void>? _disposeFuture;

  InferenceSession(this.db) {
    if (db != null) _service = QaService(db!);
    InferenceSettings.instance.addListener(_onModeChanged);
  }

  QaService? get service => _service;

  Future<void> initialize() => refresh();

  void _onModeChanged() {
    if (!_disposed) unawaited(refresh());
  }

  /// Rebuild the synthesis chain for the current inference mode.
  ///
  /// Old local model instances are disposed before a new one is created. This
  /// matters because llama.cpp installs process-global logging callbacks.
  Future<void> refresh() async {
    final database = db;
    if (_disposed || database == null) return;
    final generation = ++_generation;
    final old = _llm;
    _llm = null;
    try {
      await old?.dispose();
    } catch (e) {
      debugPrint('[InferenceSession] old LLM dispose failed: $e');
    }
    if (_disposed || generation != _generation) return;

    await InferenceSettings.instance.load();
    if (_disposed || generation != _generation) return;

    LlmService? local;
    var cloudFirst = false;
    switch (InferenceSettings.instance.mode) {
      case InferenceMode.retrievalOnly:
        break;
      case InferenceMode.localLlm:
        local = await _resolveLocal();
        break;
      case InferenceMode.cloudFirst:
        local = await _resolveLocal();
        cloudFirst = true;
        break;
    }
    if (_disposed || generation != _generation) {
      unawaited(local?.dispose());
      return;
    }

    final cloudAvailable = cloudFirst && await _cloudEnabled();
    if (_disposed || generation != _generation) {
      unawaited(local?.dispose());
      return;
    }

    if (local == null && !cloudAvailable) {
      if (_synthesisWired || _service == null) {
        _service = QaService(database);
      }
      _synthesisWired = false;
      notifyListeners();
      debugPrint('[InferenceSession] wired: retrieval-only');
      return;
    }

    _llm = local;
    _synthesisWired = true;
    _service = QaService(
      database,
      synthesizer: RagSynthesizer(
        local,
        cloudProvider: cloudFirst ? _loadCloudConfig : null,
      ),
    );
    notifyListeners();
    debugPrint(
      '[InferenceSession] wired: mode=${InferenceSettings.instance.mode} '
      'local=${local != null}, cloud=$cloudFirst',
    );

    if (local != null) unawaited(_preloadLocal(local, generation));
  }

  Future<void> _preloadLocal(LlmService llm, int generation) async {
    final state = LocalModelState.instance;
    state.reportLoading();
    final ok = await llm.preload();
    if (_disposed || generation != _generation) return;
    if (ok) {
      state.reportLoaded();
    } else {
      state.reportFailed(llm.loadError ?? '未知错误');
    }
  }

  Future<LlmService?> _resolveLocal() async {
    try {
      final path = await LlmModelResolver.resolve();
      if (path == null) return null;
      final llm = LlmService(modelPath: path);
      return llm.isAvailable ? llm : null;
    } catch (e) {
      debugPrint('[InferenceSession] local LLM init failed: $e');
      return null;
    }
  }

  Future<bool> _cloudEnabled() async {
    try {
      return (await CloudConfigStore.load()).isConfigured;
    } catch (e) {
      debugPrint('[InferenceSession] cloud config load failed: $e');
      return false;
    }
  }

  Future<CloudConfig?> _loadCloudConfig() async {
    try {
      return await CloudConfigStore.load();
    } catch (e) {
      debugPrint('[InferenceSession] cloud config load failed: $e');
      return null;
    }
  }

  Future<void> disposeAsync() {
    return _disposeFuture ??= _disposeInternal();
  }

  Future<void> _disposeInternal() async {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    InferenceSettings.instance.removeListener(_onModeChanged);
    final old = _llm;
    _llm = null;
    try {
      await old?.dispose();
    } catch (e) {
      debugPrint('[InferenceSession] dispose failed: $e');
    }
    _disposeNotifier();
  }

  @override
  void dispose() {
    if (!_notifierDisposed) {
      _notifierDisposed = true;
      super.dispose();
    }
    unawaited(disposeAsync());
  }

  void _disposeNotifier() {
    if (_notifierDisposed) return;
    _notifierDisposed = true;
    super.dispose();
  }
}
