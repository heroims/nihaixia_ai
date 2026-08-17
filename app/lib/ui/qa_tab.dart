import 'package:flutter/material.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'widgets/disclaimer_banner.dart';

class QaTab extends StatefulWidget {
  final QaService? service;
  const QaTab({super.key, this.service});
  @override
  State<QaTab> createState() => _QaTabState();
}

class _QaTabState extends State<QaTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _answer = '';
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    final service = widget.service;
    if (service == null) {
      setState(() => _answer = '（检索层未接线，将在 M5 完成。输入：$q）');
      return;
    }
    setState(() => _loading = true);
    final r = await service.answer(q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _answer = r.answer;
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
              onSubmitted: (_) => _ask(),
              decoration: const InputDecoration(
                hintText: '问倪海厦经方…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: _ask, child: const Text('问')),
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
    return Text(_answer.isEmpty ? '输入问题，如「小柴胡汤什么时候用」' : _answer);
  }
}