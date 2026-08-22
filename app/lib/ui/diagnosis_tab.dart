import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nihaixia_app/llm/inference_session.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'package:nihaixia_app/rules/diagnosis_service.dart';
import 'package:nihaixia_app/rules/diagnostic_engine.dart';

import 'widgets/disclaimer_banner.dart';
import 'widgets/source_list.dart';
import 'widgets/warning_card.dart';

class DiagnosisTab extends StatefulWidget {
  final InferenceSession? session;

  /// Test/embedding seam. Production uses the shared [session].
  final DiagnosisService? diagnosisService;

  const DiagnosisTab({super.key, this.session, this.diagnosisService});

  @override
  State<DiagnosisTab> createState() => _DiagnosisTabState();
}

enum _DiagnosisPhase { editing, submitting, result, error }

class _DiagnosisTabState extends State<DiagnosisTab> {
  SymptomInput _input = const SymptomInput();
  DiagnosisResponse? _response;
  String? _error;
  int _q = 0;
  int _requestId = 0;
  _DiagnosisPhase _phase = _DiagnosisPhase.editing;

  static const _questions = [
    '1/4 您怕冷、怕风，还是怕热？',
    '2/4 出汗情况？',
    '3/4 有头项/颈项强痛或身体酸痛吗？',
    '4/4 还有口渴或发热吗？',
  ];

  @override
  void initState() {
    super.initState();
    widget.session?.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.session?.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted && _phase == _DiagnosisPhase.editing) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const DisclaimerBanner(),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_phase == _DiagnosisPhase.editing) _buildQuestion(),
            if (_phase == _DiagnosisPhase.submitting) _buildSubmitting(),
            if (_phase == _DiagnosisPhase.result) _buildResult(),
            if (_phase == _DiagnosisPhase.error) _buildError(),
          ],
        ),
      ),
    ]);
  }

  Widget _buildQuestion() {
    final isLast = _q == _questions.length - 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (_q > 0)
          IconButton(
            tooltip: '返回上一问',
            onPressed: () => setState(() => _q--),
            icon: const Icon(Icons.arrow_back),
          ),
        Expanded(
          child: Text(
            _questions[_q],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: (_q + 1) / _questions.length),
      const SizedBox(height: 12),
      ..._options(),
      if (isLast) ...[
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _hasSymptoms ? _submit : null,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('整合症状并开始分析'),
          ),
        ),
        if (!_hasSymptoms)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('至少选择一项症状后才能开始分析。',
                style: TextStyle(color: Colors.orange)),
          ),
      ],
      if (_q > 0)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.refresh),
            label: const Text('重新开始'),
          ),
        ),
    ]);
  }

  Widget _buildSubmitting() => const Column(
        children: [
          SizedBox(height: 80),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在整合症状、检索知识库并生成分析…'),
        ],
      );

  Widget _buildResult() {
    final response = _response!;
    final hint = response.ruleHint;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_resultTitle(hint),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      _channelChip(response.qa),
      WarningCard(text: response.qa.hasAnswer ? response.qa.answer : null),
      MarkdownBody(
        data: response.qa.answer,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
      ),
      if (hint.suggestedFormula.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('规则基线线索：${hint.suggestedFormula}'),
        ),
      const SizedBox(height: 8),
      SourceList(sources: response.qa.sources),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        OutlinedButton.icon(
          onPressed: _edit,
          icon: const Icon(Icons.edit),
          label: const Text('修改症状'),
        ),
        FilledButton.tonal(
          onPressed: _restart,
          child: const Text('重新开始'),
        ),
      ]),
    ]);
  }

  Widget _buildError() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline, color: Colors.orange, size: 36),
        const SizedBox(height: 8),
        Text(_error ?? '分析失败，请重试。'),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          FilledButton(onPressed: _submit, child: const Text('重试')),
          OutlinedButton(onPressed: _edit, child: const Text('修改症状')),
        ]),
      ]);

  List<Widget> _options() {
    switch (_q) {
      case 0:
        return [
          _choice('怕冷', _input.cold == ColdState.aversionToCold,
              () => _select(cold: ColdState.aversionToCold)),
          _choice('怕风', _input.cold == ColdState.aversionToWind,
              () => _select(cold: ColdState.aversionToWind)),
          _choice('怕热', _input.cold == ColdState.aversionToHeat,
              () => _select(cold: ColdState.aversionToHeat)),
          _choice('不确定/跳过', false, _next),
        ];
      case 1:
        return [
          _choice('有汗', _input.sweat == SweatState.hasSweat,
              () => _select(sweat: SweatState.hasSweat)),
          _choice('没汗', _input.sweat == SweatState.noSweat,
              () => _select(sweat: SweatState.noSweat)),
          _choice('不确定/跳过', false, _next),
        ];
      case 2:
        return [
          _choice('头项强痛', _input.painNeck, () => _select(painNeck: true)),
          _choice('身体酸痛', _input.bodyAche, () => _select(bodyAche: true)),
          _choice('都没有/跳过', false, _next),
        ];
      default:
        return [
          _choice('口渴', _input.thirst, () => _toggle(thirst: !_input.thirst)),
          _choice('发热', _input.fever, () => _toggle(fever: !_input.fever)),
        ];
    }
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) => Card(
        color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
        child: ListTile(
          title: Text(label),
          trailing: selected ? const Icon(Icons.check) : null,
          onTap: onTap,
        ),
      );

  bool get _hasSymptoms =>
      _input.cold != ColdState.unknown ||
      _input.sweat != SweatState.unknown ||
      _input.painNeck ||
      _input.bodyAche ||
      _input.thirst ||
      _input.fever;

  void _select({
    SweatState? sweat,
    ColdState? cold,
    bool? painNeck,
    bool? bodyAche,
  }) {
    setState(() {
      _input = SymptomInput(
        sweat: sweat ?? _input.sweat,
        cold: cold ?? _input.cold,
        painNeck: painNeck ?? _input.painNeck,
        bodyAche: bodyAche ?? _input.bodyAche,
        thirst: _input.thirst,
        fever: _input.fever,
      );
      if (_q < _questions.length - 1) _q++;
    });
  }

  void _toggle({bool? thirst, bool? fever}) => setState(() {
        _input = SymptomInput(
          sweat: _input.sweat,
          cold: _input.cold,
          painNeck: _input.painNeck,
          bodyAche: _input.bodyAche,
          thirst: thirst ?? _input.thirst,
          fever: fever ?? _input.fever,
        );
      });

  void _next() {
    if (_q < _questions.length - 1) setState(() => _q++);
  }

  Future<void> _submit() async {
    if (!_hasSymptoms || _phase == _DiagnosisPhase.submitting) return;
    final service = widget.diagnosisService ??
        (widget.session?.service == null
            ? null
            : DiagnosisService(qaService: widget.session!.service));
    if (service == null) {
      setState(() {
        _phase = _DiagnosisPhase.error;
        _error = '推理服务尚未就绪，请稍后重试。';
      });
      return;
    }
    final id = ++_requestId;
    setState(() {
      _phase = _DiagnosisPhase.submitting;
      _error = null;
    });
    try {
      final response = await service.diagnose(_input);
      if (!mounted || id != _requestId) return;
      setState(() {
        _response = response;
        _phase = _DiagnosisPhase.result;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _phase = _DiagnosisPhase.error;
        _error = '分析暂时失败：$e';
      });
    }
  }

  void _edit() => setState(() {
        _phase = _DiagnosisPhase.editing;
        _q = _questions.length - 1;
        _response = null;
      });

  void _restart() => setState(() {
        ++_requestId;
        _input = const SymptomInput();
        _response = null;
        _error = null;
        _phase = _DiagnosisPhase.editing;
        _q = 0;
      });

  String _resultTitle(DiagnosisResult result) => switch (result.status) {
        DiagnosisStatus.matched => '规则基线：${result.jing}',
        DiagnosisStatus.insufficient => '信息不足，无法辨证',
        DiagnosisStatus.unmatched => '辨证未确定，交由证据分析',
      };

  Widget _channelChip(QaResult result) {
    final (label, color) = switch (result.channel) {
      'cloud' => ('云端模型', Colors.indigo),
      'local' => ('端侧模型', Colors.teal),
      _ => ('知识库检索', Colors.grey),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Chip(
            label: Text(label),
            avatar: Icon(Icons.route, size: 16, color: color)),
        if (result.channelNote != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(result.channelNote!,
                  style: const TextStyle(fontSize: 11, color: Colors.orange)),
            ),
          ),
      ]),
    );
  }
}
