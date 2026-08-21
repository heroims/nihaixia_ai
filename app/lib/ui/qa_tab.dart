import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/core/models.dart';
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
  bool _loading = false;
  // 请求令牌：并发防抖。每次提交自增，早先 in-flight 请求完成后若令牌已过期
  // 则丢弃结果，保证「后提交者胜出」且 _loading 不被旧请求提前清掉（T18-1）。
  int _req = 0;

  @override
  void initState() {
    super.initState();
    final db = widget.db;
    if (db != null) _service = QaService(db);
    _initLlm();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    unawaited(_llm?.dispose());
    super.dispose();
  }

  /// 异步接线 LLM 通道：云端配置或端侧模型任一可用 → 以带 RAG 合成器的
  /// QaService 替换纯检索服务；全不可用 → 保持纯检索，永不崩溃。
  Future<void> _initLlm() async {
    final db = widget.db;
    if (db == null) return;
    LlmService? llm;
    try {
      final path = await LlmModelResolver.resolve();
      debugPrint('[QaTab] LLM resolve: path=${path ?? "null"}');
      if (path != null) {
        final l = LlmService(modelPath: path);
        if (l.isAvailable) {
          llm = l;
        } else {
          debugPrint('[QaTab] LLM not available (model file missing/failed)');
        }
      }
    } catch (e) {
      debugPrint('[QaTab] LLM init failed: $e');
    }
    // 云端配置不在此处快照：合成器每次提问时实时读取，设置保存后立即生效。
    if (llm == null) {
      final cfg = await CloudConfigStore.load();
      if (!cfg.isEnabled) return; // 无任何通道 → 纯检索
    }
    if (!mounted) {
      unawaited(llm?.dispose());
      return;
    }
    setState(() {
      _llm = llm;
      _service = QaService(
          db,
          synthesizer: RagSynthesizer(llm, cloudProvider: () async {
            try {
              return await CloudConfigStore.load();
            } catch (e) {
              debugPrint('[QaTab] cloud config load failed: $e');
              return null;
            }
          }));
    });
    debugPrint('[QaTab] LLM wired: local=${llm != null}, cloud=per-call');
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
}