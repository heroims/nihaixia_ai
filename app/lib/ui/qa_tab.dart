import 'package:flutter/material.dart';
import 'widgets/disclaimer_banner.dart';

class QaTab extends StatefulWidget {
  const QaTab({super.key});
  @override
  State<QaTab> createState() => _QaTabState();
}

class _QaTabState extends State<QaTab> {
  final _controller = TextEditingController();
  String _answer = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ask() {
    // M5 接入检索链路（Task 18）
    setState(() {
      _answer = '（检索层尚未接线，将在 M5 完成。输入：${_controller.text.trim()}）';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const DisclaimerBanner(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Text(_answer.isEmpty ? '输入问题，如「小柴胡汤什么时候用」' : _answer),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: '问倪海厦经方…', border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: _ask, child: const Text('问')),
        ]),
      ),
    ]);
  }
}