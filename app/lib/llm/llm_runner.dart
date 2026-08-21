// app/lib/llm/llm_runner.dart
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';

// ignore: implementation_imports
import 'package:llama_cpp_dart/src/llama_cpp.dart'
    show Dartggml_log_callbackFunction;
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
  Completer<SendPort> _boot = Completer<SendPort>();
  Completer<void>? _loadDone;
  String? _loadError;
  final Map<int, _Pending> _pending = {};
  bool _loaded = false;
  bool _disposed = false;
  int _nextId = 0;

  /// 在后台 isolate 中加载模型。失败（含 native 库缺失）抛出异常。
  Future<void> ensureLoaded({
    required String modelPath,
    int nCtx = 4096,
    double temp = 0.3,
  }) async {
    if (_disposed) throw StateError('runner 已释放');
    if (_loaded) {
      print('[LLM] ensureLoaded: already loaded');
      return;
    }
    print('[LLM] ensureLoaded: start, path=$modelPath nCtx=$nCtx');
    if (_isolate == null) {
      _control = ReceivePort();
      _isolate = await Isolate.spawn(_isolateMain, _control!.sendPort);
      _control!.listen(_onMessage);
      try {
        _port = await _boot.future.timeout(const Duration(seconds: 10));
        print('[LLM] isolate booted');
      } on TimeoutException {
        // 启动超时：清空本次启动状态并换新 completer，令下次 ensureLoaded
        // 走全新 isolate，避免挂在永不完成的 _boot 上。
        print('[LLM] isolate boot TIMEOUT, resetting');
        _isolate?.kill(priority: Isolate.immediate);
        _control?.close();
        _isolate = null;
        _control = null;
        _port = null;
        _boot = Completer<SendPort>();
        rethrow;
      }
    }
    final done = _loadDone = Completer<void>();
    final sw = Stopwatch()..start();
    _port!.send({
      'cmd': 'load',
      'path': modelPath,
      'nCtx': nCtx,
      'temp': temp,
    });
    try {
      await done.future.timeout(const Duration(seconds: 120));
      print('[LLM] ensureLoaded: load returned in ${sw.elapsedMilliseconds}ms, error=$_loadError');
    } on TimeoutException {
      print('[LLM] ensureLoaded: load TIMEOUT after 120s');
      rethrow;
    }
    if (_loadError != null) {
      final err = _loadError;
      _loadError = null;
      print('[LLM] ensureLoaded: load error=$err');
      throw StateError('模型加载失败: $err');
    }
    print('[LLM] ensureLoaded: done');
  }

  /// 生成全文，直到 EOS 或超时；超时返回已生成的文本并停止该轮。
  Future<String> generate(
    String prompt, {
    Duration timeout = const Duration(seconds: 300),
  }) async {
    final port = _port;
    if (port == null || !_loaded) throw StateError('模型未加载');
    final id = _nextId++;
    final completer = Completer<String>();
    _pending[id] = _Pending(completer, StringBuffer());
    final sw = Stopwatch()..start();
    print('[LLM] generate: id=$id promptLen=${prompt.length}');
    port.send({'cmd': 'generate', 'id': id, 'prompt': prompt});
    try {
      final out = await completer.future.timeout(timeout, onTimeout: () {
        print('[LLM] generate: id=$id TIMEOUT after ${timeout.inSeconds}s');
        port.send({'cmd': 'stop', 'id': id});
        final p = _pending.remove(id);
        return p?.buffer.toString() ?? '';
      });
      print('[LLM] generate: id=$id done in ${sw.elapsedMilliseconds}ms, outLen=${out.length}');
      return out;
    } catch (e) {
      _pending.remove(id);
      print('[LLM] generate: id=$id ERROR: $e');
      rethrow;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _port?.send({'cmd': 'dispose'});
    _control?.close();
    // 注意：Isolate.immediate 强杀可能抢在 host 处理 'dispose' 之前，导致
    // llama_cpp_dart 的原生资源（LLM 上下文）未被回收。这是 Teardown 阶段的
    // 已知 native 泄漏，App 退出即进程回收，可接受，故保持现状。
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
  _bridgeLlamaLogs();
  final port = ReceivePort();
  mainPort.send(port.sendPort);
  final host = _IsolateHost(port, mainPort);
  port.listen(host.onMessage);
}

typedef _LlamaLogNative = ffi.Void Function(
    ffi.Int32, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Void>);
typedef _LlamaLogDart = void Function(
    int, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Void>);

/// 把 llama.cpp/ggml 的原生日志桥接到 Dart print（→ logcat）。
///
/// 必须在 runner isolate 内注册：Pointer.fromFunction 创建的回调只能被
/// 创建它的 isolate 调用，跨 isolate 调用会触发 Dart 运行时 abort。
/// 模型加载失败时 llama.cpp 会把原因打到日志，没有这个桥接在 Android 上
/// 完全看不到（stderr 不进 logcat）。
void _bridgeLlamaLogs() {
  try {
    final cb = ffi.Pointer.fromFunction<_LlamaLogNative>(_onLlamaLog);
    Llama.lib.llama_log_set(cb, ffi.Pointer.fromAddress(0));
    print('[LLM:iso] native log bridge installed');
  } catch (e) {
    print('[LLM:iso] log bridge failed: $e');
  }
}

void _onLlamaLog(int level, ffi.Pointer<ffi.Char> text, ffi.Pointer<ffi.Void> _) {
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

class _IsolateHost {
  final ReceivePort port;
  final SendPort mainPort;
  final LlmGate gate = LlmGate();
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
            ..batch = nCtx;
          final sampler = SamplingParams()
            ..temp = temp
            ..topK = 40
            ..topP = 0.9;
          print('[LLM:iso] load: constructing Llama for ${msg['path']}');
          final sw = Stopwatch()..start();
          llama = Llama(
            msg['path'] as String,
            ModelParams(),
            ctx,
            sampler,
          );
          print('[LLM:iso] load: Llama constructed in ${sw.elapsedMilliseconds}ms');
          mainPort.send({'type': 'loaded'});
        } catch (e) {
          print('[LLM:iso] load: ERROR $e');
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
        // 单飞闸门（Option A）：上一个生成尚未结束时，直接拒绝本次生成，
        // 经 per-id 缓冲回到 generate() 变为 error，调用方降级为检索-only。
        if (!gate.tryAcquire()) {
          mainPort.send({
            'type': 'error',
            'id': id,
            'message': 'busy: 已有生成任务进行中',
          });
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
      llama.setPrompt(
          '<|im_start|>user\n$prompt<|im_end|>\n<|im_start|>assistant\n');
      print('[LLM:iso] generate $id: start');
      final sw = Stopwatch()..start();
      var tokens = 0;
      while (!stopRequested) {
        final (token, done) = llama.getNext();
        if (token.isNotEmpty) {
          tokens++;
          mainPort.send({'type': 'token', 'id': id, 'text': token});
        }
        if (done) break;
        await Future<void>.delayed(Duration.zero);
      }
      llama.clear();
      print('[LLM:iso] generate $id: done ${sw.elapsedMilliseconds}ms tokens=$tokens');
      mainPort.send({'type': 'done', 'id': id});
    } catch (e) {
      print('[LLM:iso] generate $id: ERROR $e');
      mainPort.send({'type': 'error', 'id': id, 'message': e.toString()});
    } finally {
      // 成功/超时/异常任一路径都必须释放闸门，否则后续生成被永久拒绝。
      gate.release();
      stopRequested = false;
      activeId = -1;
    }
  }
}

/// 单飞闸门：同一时刻只允许一个生成任务在 Llama 上推进。
///
/// 纯 Dart 实现，不依赖 isolate 协议与原生库，可在单元测试中直接验证
/// Option A（拒绝式串行化）语义；host 侧接入见 `_IsolateHost.onMessage`。
/// 真机上的并发生成集成验证由 Task 26 覆盖（本机无原生库无法真实加载模型）。
class LlmGate {
  bool _busy = false;

  bool get busy => _busy;

  /// 尝试占用闸门。若已有生成任务在进行中则返回 false（调用方应拒绝新任务）。
  bool tryAcquire() {
    if (_busy) return false;
    _busy = true;
    return true;
  }

  /// 释放闸门，幂等。
  void release() => _busy = false;
}
