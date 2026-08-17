import 'package:flutter/material.dart';
import 'widgets/disclaimer_banner.dart';
import '../rules/diagnostic_engine.dart';

class DiagnosisTab extends StatefulWidget {
  const DiagnosisTab({super.key});
  @override
  State<DiagnosisTab> createState() => _DiagnosisTabState();
}

class _DiagnosisTabState extends State<DiagnosisTab> {
  DiagnosisResult? _result;
  final int _step = 0;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const DisclaimerBanner(),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(_buildSurvey(), style: const TextStyle(fontSize: 16)),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Text('辨证：${_result!.jing}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_result!.message),
            if (_result!.suggestedFormula.isNotEmpty)
              Text('代表方方向：${_result!.suggestedFormula}'),
          ],
        ]),
      ),
    ]);
  }

  String _buildSurvey() => '引导式诊断（步骤 $_step）\n'
      '请依次回答：\n1. 怕冷还是怕热？2. 有汗还是没汗？\n'
      '3. 是否头痛/脖子痛？4. 是否口渴？\n'
      '（本步骤 M5 接入问卷选项与规则引擎）';
}