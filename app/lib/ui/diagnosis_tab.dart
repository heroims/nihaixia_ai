import 'package:flutter/material.dart';
import '../rules/diagnostic_engine.dart';
import 'widgets/disclaimer_banner.dart';
import 'widgets/warning_card.dart';

class DiagnosisTab extends StatefulWidget {
  const DiagnosisTab({super.key});
  @override
  State<DiagnosisTab> createState() => _DiagnosisTabState();
}

class _DiagnosisTabState extends State<DiagnosisTab> {
  SymptomInput _input = const SymptomInput();
  DiagnosisResult? _result;
  int _q = 0;

  static const _questions = [
    '1/4 您怕冷、怕风，还是怕热？',
    '2/4 出汗情况？',
    '3/4 有头项/颈项强痛吗？',
    '4/4 有口渴或发热吗？',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const DisclaimerBanner(),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(_questions[_q], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._options(),
          const SizedBox(height: 16),
          if (_result != null) ...[
            Card(elevation: 2, child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_resultTitle(_result!.status, _result!.jing),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(_result!.message),
                if (_result!.suggestedFormula.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text('代表方方向：${_result!.suggestedFormula}')),
              ]),
            )),
            const SizedBox(height: 8),
            WarningCard(text: _result!.message),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(onPressed: _restart, child: const Text('重新开始')),
            ),
          ],
        ]),
      ),
    ]);
  }

  List<Widget> _options() {
    switch (_q) {
      case 0:
        return [
          _choice('怕冷', () => _set(cold: ColdState.aversionToCold)),
          _choice('怕风', () => _set(cold: ColdState.aversionToWind)),
          _choice('怕热', () => _set(cold: ColdState.aversionToHeat)),
          _choice('不确定/跳过', _next),
        ];
      case 1:
        return [
          _choice('有汗', () => _set(sweat: SweatState.hasSweat)),
          _choice('没汗', () => _set(sweat: SweatState.noSweat)),
          _choice('不确定/跳过', _next),
        ];
      case 2:
        return [
          _choice('头项强痛', () => _set(painNeck: true)),
          _choice('身体酸痛', () => _set(bodyAche: true)),
          _choice('都没有/跳过', _next),
        ];
      default:
        return [
          _choice('口渴', () => _set(thirst: true)),
          _choice('发热', () => _set(fever: true)),
          _choice('都没有/完成辨证', _finish),
        ];
    }
  }

  Widget _choice(String label, VoidCallback onTap) =>
      Card(child: ListTile(title: Text(label), onTap: onTap));

  void _set({SweatState? sweat, ColdState? cold, bool? painNeck, bool? bodyAche, bool? thirst, bool? fever}) {
    _input = SymptomInput(
      sweat: sweat ?? _input.sweat,
      cold: cold ?? _input.cold,
      painNeck: painNeck ?? _input.painNeck,
      bodyAche: bodyAche ?? _input.bodyAche,
      thirst: thirst ?? _input.thirst,
      fever: fever ?? _input.fever,
    );
    _next();
  }

  void _next() {
    if (_q < _questions.length - 1) {
      setState(() => _q++);
    } else {
      _finish();
    }
  }

  void _finish() => setState(() {
        _result = DiagnosticEngine.evaluate(_input);
      });

  void _restart() => setState(() {
        _input = const SymptomInput();
        _result = null;
        _q = 0;
      });

  String _resultTitle(DiagnosisStatus status, String jing) => switch (status) {
        DiagnosisStatus.matched => '辨证：$jing',
        DiagnosisStatus.insufficient => '信息不足，无法辨证',
        DiagnosisStatus.unmatched => '辨证未确定',
      };
}