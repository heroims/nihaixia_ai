// app/lib/llm/llm_runner.dart
import 'dart:async';
import 'dart:isolate';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';

/// llama_cpp_dart 0.0.7 的隔离岛 Runner。
///
/// 计划伪代码基于 0.2.x 的 LlamaParent/LlamaLoad/LlamaStatus API，但本项目
/// Flutter 3.19.4 / Dart 3.3.2 无法解析 0.2.x（typed_isolate 需要 meta
/// ^1.15.0，Flutter SDK 钉死 meta 1.11.0），实际解析到 0.0.7。
/// 0.0.7 无 LlamaParent，改为在独立 isolate 内直接持有同步 `Llama`，
/// 通过消息协议暴露 ensureLoaded / generate / dispose。
class LlmRunner {
  Isolate? _isolate;
  ReceivePort? _control;
  SendPort? _port;
  final Completer<SendPort> _boot = Completer<SendPort>();
  Completer<void>? _loadDone;
  String? _loadError;
  final Map<int, _Pending> _pending = {};
  bool _loaded = false;
  bool _disposed = false;
  int _nextId = 0;

  /// 在后台 isolate 中加载模型。失败（含 native 库缺失）抛出异常。
  Future<void> ensureLoaded({
    required String modelPath,
    int nCtx = 2048,
    double temp = 0.3,
  }) async {
    if (_disposed) throw StateError('runner 已释放');
    if (_loaded) return;
    if (_isolate == null) {
      _control = ReceivePort();
      _isolate = await Isolate.spawn(_isolateMain, _control!.sendPort);
      _control!.listen(_onMessage);
      _port = await _boot.future.timeout(const Duration(seconds: 10));
    }
    final done = _loadDone = Completer<void>();
    _port!.send({
      'cmd': 'load',
      'path': modelPath,
      'nCtx': nCtx,
      'temp': temp,
    });
    await done.future.timeout(const Duration(seconds: 120));
    if (_loadError != null) {
      final err = _loadError;
      _loadError = null;
      throw StateError('模型加载失败: $err');
    }
  }

  /// 生成全文，直到 EOS 或超时；超时返回已生成的文本并停止该轮。
  Future<String> generate(
    String prompt, {
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final port = _port;
    if (port == null || !_loaded) throw StateError('模型未加载');
    final id = _nextId++;
    final completer = Completer<String>();
    _pending[id] = _Pending(completer, StringBuffer());
    port.send({'cmd': 'generate', 'id': id, 'prompt': prompt});
    try {
      return await completer.future.timeout(timeout, onTimeout: () {
        port.send({'cmd': 'stop', 'id': id});
        final p = _pending.remove(id);
        return p?.buffer.toString() ?? '';
      });
    } catch (e) {
      _pending.remove(id);
      rethrow;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _port?.send({'cmd': 'dispose'});
    _control?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _port = null;
    _isolate = null;
    _control = null;
    _loaded = false;
  }

  void _onMessage(dynamic msg) {
    if (msg is SendPort) {
      if (!_boot.isCompleted) _boot.complete(msg);
      return;
    }
    if (msg is! Map) return;
    switch (msg['type']) {
      case 'loaded':
        _loaded = true;
        _loadDone?.complete();
        break;
      case 'load_error':
        _loadError = msg['message'] as String;
        _loadDone?.complete();
        break;
      case 'token':
        final id = msg['id'] as int;
        _pending[id]?.buffer.write(msg['text'] as String);
        break;
      case 'done':
        final id = msg['id'] as int;
        final p = _pending.remove(id);
        if (p != null && !p.completer.isCompleted) {
          p.completer.complete(p.buffer.toString());
        }
        break;
      case 'error':
        final id = msg['id'] as int;
        final p = _pending.remove(id);
        if (p != null && !p.completer.isCompleted) {
          p.completer.completeError(StateError(msg['message'] as String));
        }
        break;
    }
  }
}

class _Pending {
  final Completer<String> completer;
  final StringBuffer buffer;
  _Pending(this.completer, this.buffer);
}

void _isolateMain(SendPort mainPort) {
  final port = ReceivePort();
  mainPort.send(port.sendPort);
  final host = _IsolateHost(port, mainPort);
  port.listen(host.onMessage);
}

class _IsolateHost {
  final ReceivePort port;
  final SendPort mainPort;
  Llama? llama;
  bool stopRequested = false;
  int activeId = -1;

  _IsolateHost(this.port, this.mainPort);

  void onMessage(dynamic msg) {
    if (msg is! Map) return;
    switch (msg['cmd']) {
      case 'load':
        try {
          final nCtx = msg['nCtx'] as int;
          final temp = (msg['temp'] as num).toDouble();
          final ctx = ContextParams()
            ..context = nCtx
            ..batch = 512;
          final sampler = SamplingParams()
            ..temp = temp
            ..topK = 40
            ..topP = 0.9;
          llama = Llama(
            msg['path'] as String,
            ModelParams(),
            ctx,
            sampler,
          );
          mainPort.send({'type': 'loaded'});
        } catch (e) {
          mainPort.send({'type': 'load_error', 'message': e.toString()});
        }
        break;
      case 'generate':
        final id = msg['id'] as int;
        final l = llama;
        if (l == null) {
          mainPort.send({'type': 'error', 'id': id, 'message': '模型未加载'});
          break;
        }
        stopRequested = false;
        activeId = id;
        unawaited(_generate(l, id, msg['prompt'] as String));
        break;
      case 'stop':
        if (msg['id'] == activeId) stopRequested = true;
        break;
      case 'dispose':
        llama?.dispose();
        llama = null;
        port.close();
        break;
    }
  }

  Future<void> _generate(Llama llama, int id, String prompt) async {
    try {
      llama.setPrompt(prompt);
      while (!stopRequested) {
        final (token, done) = llama.getNext();
        if (token.isNotEmpty) {
          mainPort.send({'type': 'token', 'id': id, 'text': token});
        }
        if (done) break;
        await Future<void>.delayed(Duration.zero);
      }
      llama.clear();
      mainPort.send({'type': 'done', 'id': id});
    } catch (e) {
      mainPort.send({'type': 'error', 'id': id, 'message': e.toString()});
    } finally {
      stopRequested = false;
      activeId = -1;
    }
  }
}
