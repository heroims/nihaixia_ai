import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/core/models.dart';
import 'package:nihaixia_app/llm/inference_session.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'package:nihaixia_app/retrieval/consultation_session.dart';
import 'widgets/disclaimer_banner.dart';
import 'widgets/source_list.dart';
import 'widgets/warning_card.dart';

class QaTab extends StatefulWidget {
  final InferenceSession? session;
  final AppDatabase? db;
  const QaTab({super.key, this.session, this.db});
  @override
  State<QaTab> createState() => _QaTabState();
}

class _QaTabState extends State<QaTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  ConsultationSession? _conversation;
  String _answer = '';
  bool _hasAnswer = false;
  List<SearchHit> _sources = const [];
  String _channel = 'retrieval';
  String? _channelNote;
  bool _loading = false;
  // 请求令牌：并发防抖。每次提交自增，早先 in-flight 请求完成后若令牌已过期
  // 则丢弃结果，保证「后提交者胜出」且 _loading 不被旧请求提前清掉（T18-1）。
  int _req = 0;

  @override
  void initState() {
    super.initState();
    widget.session?.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.session?.removeListener(_onSessionChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _ask() async {
    if (_loading) return;
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    final service = widget.session?.service ??
        (widget.db == null ? null : QaService(widget.db!));
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
    final synth = service.synthesizer;
    if (synth != null && synth.enabled) {
      _conversation ??= ConsultationSession(
        synthesize: (prompt) async {
          final current = widget.session?.service?.synthesizer;
          return (current ?? synth).generateInstruction(prompt);
        },
        retrieve: (query) => QaService(service.db).answer(query),
        answerKnowledge: (query) =>
            (widget.session?.service ?? service).answer(query),
      );
      await _conversation!.send(q);
      if (!mounted || id != _req) return;
      setState(() {
        _loading = false;
        _controller.clear();
        _channelNote = null;
      });
      _scrollToLatest();
      return;
    }
    if (_conversation != null) {
      setState(() {
        _loading = false;
        _channelNote = '模型当前不可用，请恢复连接后继续，或开始新对话进行知识查询。';
      });
      return;
    }
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

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _confirm() async {
    if (_loading) return;
    final id = ++_req;
    setState(() => _loading = true);
    await _conversation!.send('信息无误，请形成参考结果', confirmed: true);
    if (mounted && id == _req) {
      setState(() => _loading = false);
      _scrollToLatest();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const DisclaimerBanner(),
      if (_conversation != null)
        Row(children: [
          const SizedBox(width: 12),
          Text(switch (_conversation!.stage) {
            ConsultationStage.collecting => '了解症状',
            ConsultationStage.confirming => '请核对信息',
            ConsultationStage.complete => '本轮已结束',
          }),
          const Spacer(),
          TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() {
                        _conversation = null;
                        _answer = '';
                        _channelNote = null;
                        _controller.clear();
                        ++_req;
                      }),
              child: const Text('新对话')),
        ]),
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
                hintText: '描述症状，或询问经方知识…',
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
    if (_conversation != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final message in _conversation!.messages)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.user
                            ? '你'
                            : switch (message.channel) {
                                'cloud' => '助手 · 云端模型',
                                'local' => '助手 · 端侧模型',
                                _ => '助手',
                              }),
                        const SizedBox(height: 6),
                        if (!message.user) WarningCard(text: message.text),
                        MarkdownBody(data: message.text, selectable: true),
                        if (message.note != null) Text(message.note!),
                        if (message.sources.isNotEmpty)
                          SourceList(sources: message.sources),
                      ]))),
        if (_channelNote != null) Text(_channelNote!),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_loading && _conversation!.stage == ConsultationStage.confirming)
          FilledButton(onPressed: _confirm, child: const Text('信息无误，形成参考结果')),
      ]);
    }
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
            color: color.withValues(alpha: 0.12),
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
