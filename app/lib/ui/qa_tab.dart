import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/core/models.dart';
import 'package:nihaixia_app/llm/inference_settings.dart';
import 'package:nihaixia_app/llm/local_model_state.dart';
import 'package:nihaixia_app/llm/llm_service.dart';
import 'package:nihaixia_app/llm/model_resolver.dart';
import 'package:nihaixia_app/llm/rag_synthesizer.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'widgets/disclaimer_banner.dart';
import 'widgets/source_list.dart';
import 'widgets/warning_card.dart';

class QaTab extends StatefulWidget {
  final AppDatabase? db;
  const QaTab({super.key, this.db});
  @override
  State<QaTab> createState() => _QaTabState();
}

class _QaTabState extends State<QaTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  QaService? _service;
  LlmService? _llm;
  String _answer = '';
  bool _hasAnswer = false;
  List<SearchHit> _sources = const [];
  String _channel = 'retrieval';
  String? _channelNote;
  bool _loading = false;
  // 请求令牌：并发防抖。每次提交自增，早先 in-flight 请求完成后若令牌已过期
  // 则丢弃结果，保证「后提交者胜出」且 _loading 不被旧请求提前清掉（T18-1）。
  int _req = 0;
  // 接线代数：模式快速切换时作废旧的异步接线/预热流程，防止交错泄漏。
  int _wiring = 0;

  @override
  void initState() {
    super.initState();
    final db = widget.db;
    if (db != null) _service = QaService(db);
    // 推理模式切换（设置页）→ 重新接线问答服务。
    InferenceSettings.instance.addListener(_onModeChanged);
    _initLlm();
  }

  @override
  void dispose() {
    InferenceSettings.instance.removeListener(_onModeChanged);
    _controller.dispose();
    _scrollController.dispose();
    unawaited(_llm?.dispose());
    super.dispose();
  }

  void _onModeChanged() {
    if (!mounted) return;
    debugPrint('[QaTab] inference mode changed, rewiring...');
    unawaited(_initLlm());
  }

  /// 按推理模式异步接线问答服务：
  /// - 纯检索：不解析模型、不接合成器（省去 1.1GB 资产复制与加载）；
  /// - 端侧模型：仅本地 llama.cpp，不读云端配置；
  /// - 云端优先：云端实时读取 + 端侧兜底（默认）。
  /// 全不可用 → 保持纯检索，永不崩溃。
  Future<void> _initLlm() async {
    final db = widget.db;
    if (db == null) return;
    final gen = ++_wiring;

    // 先释放旧通道并等待其优雅收尾：llama_log_set 是进程级全局状态，
    // 新旧两个 isolate 并发注册/复位回调会竞态（旧回调悬垂 → 原生侧
    // 打日志写空地址 SIGSEGV，iOS 模拟器实测）。必须串行化销毁与创建。
    final old = _llm;
    _llm = null;
    try {
      await old?.dispose();
    } catch (_) {}
    if (gen != _wiring) return;

    await InferenceSettings.instance.load();
    if (gen != _wiring) return;
    final mode = InferenceSettings.instance.mode;
    debugPrint('[QaTab] inference mode=$mode');

    LlmService? llm;
    var wireCloud = false;
    switch (mode) {
      case InferenceMode.retrievalOnly:
        break;
      case InferenceMode.localLlm:
        llm = await _resolveLocal();
        break;
      case InferenceMode.cloudFirst:
        llm = await _resolveLocal();
        wireCloud = true;
        break;
    }
    if (gen != _wiring) {
      unawaited(llm?.dispose());
      return;
    }
    // 云端配置不在此处快照：合成器每次提问时实时读取，设置保存后立即生效。
    if (llm == null && (!wireCloud || !(await _cloudEnabled()))) {
      if (gen != _wiring) return;
      setState(() => _service = QaService(db)); // 无任何通道 → 纯检索
      debugPrint('[QaTab] wired: retrieval-only');
      return;
    }
    if (!mounted || gen != _wiring) {
      unawaited(llm?.dispose());
      return;
    }
    setState(() {
      _llm = llm;
      _service = QaService(
          db,
          synthesizer: RagSynthesizer(llm, cloudProvider: wireCloud ? _loadCloudConfig : null));
    });
    debugPrint('[QaTab] wired: mode=$mode local=${llm != null}, cloud=${wireCloud ? "per-call" : "off"}');
    // 预热加载端侧模型并上报真实加载状态（设置页展示；首次提问不再等待加载）。
    if (llm != null) unawaited(_preloadLocal(llm, gen));
  }

  Future<void> _preloadLocal(LlmService llm, int gen) async {
    final state = LocalModelState.instance;
    state.reportLoading();
    final ok = await llm.preload();
    if (gen != _wiring) return; // 已被更新的接线取代，不上报过期状态
    if (ok) {
      debugPrint('[QaTab] local model preloaded OK');
      state.reportLoaded();
    } else {
      debugPrint('[QaTab] local model preload FAILED: ${llm.loadError}');
      state.reportFailed(llm.loadError ?? '未知错误');
    }
  }

  Future<LlmService?> _resolveLocal() async {
    try {
      final path = await LlmModelResolver.resolve();
      debugPrint('[QaTab] LLM resolve: path=${path ?? "null"}');
      if (path == null) return null;
      final l = LlmService(modelPath: path);
      if (l.isAvailable) return l;
      debugPrint('[QaTab] LLM not available (model file missing/failed)');
    } catch (e) {
      debugPrint('[QaTab] LLM init failed: $e');
    }
    return null;
  }

  Future<bool> _cloudEnabled() async {
    try {
      // 仅在「云端优先」接线且配置齐全时为真；模式判断已由 wireCloud 完成。
      return (await CloudConfigStore.load()).isConfigured;
    } catch (e) {
      debugPrint('[QaTab] cloud config load failed: $e');
      return false;
    }
  }

  Future<CloudConfig?> _loadCloudConfig() async {
    try {
      return await CloudConfigStore.load();
    } catch (e) {
      debugPrint('[QaTab] cloud config load failed: $e');
      return null;
    }
  }

  Future<void> _ask() async {
    if (_loading) return;
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    final service = _service;
    if (service == null) {
      setState(() {
        _answer = '数据库不可用，无法检索。请确认应用资源完整后重试。';
        _hasAnswer = false;
        _sources = const [];
      });
      return;
    }
    final id = ++_req;
    setState(() => _loading = true);
    final r = await service.answer(q);
    if (!mounted || id != _req) return;
    setState(() {
      _loading = false;
      _answer = r.answer;
      _hasAnswer = r.hasAnswer;
      _sources = r.sources;
      _channel = r.channel;
      _channelNote = r.channelNote;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const DisclaimerBanner(),
      Expanded(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          child: _buildBody(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _loading ? null : (_) => _ask(),
              decoration: const InputDecoration(
                hintText: '问倪海厦经方…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _loading ? null : _ask,
            child: const Text('问'),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_answer.isEmpty) {
      return const Text('输入问题，如「小柴胡汤什么时候用」');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WarningCard(text: _hasAnswer ? _answer : null),
        _buildChannelChip(),
        MarkdownBody(
          data: _answer,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        ),
        const SizedBox(height: 8),
        SourceList(sources: _sources),
      ],
    );
  }

  /// 回答来源标注：让「云端优先是否真的走了云端」可见。
  Widget _buildChannelChip() {
    if (!_hasAnswer) return const SizedBox.shrink();
    final (label, color) = switch (_channel) {
      'cloud' => ('云端模型', Colors.indigo),
      'local' => ('端侧模型', Colors.teal),
      _ => ('知识库原文', Colors.grey),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: TextStyle(fontSize: 11, color: color)),
        ),
        if (_channelNote != null) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(_channelNote!,
                style: const TextStyle(fontSize: 11, color: Colors.orange)),
          ),
        ],
      ]),
    );
  }
}