import 'package:flutter/material.dart';
import 'package:nihaixia_app/core/models.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'widgets/disclaimer_banner.dart';
import 'widgets/source_list.dart';

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
  List<SearchHit> _sources = const [];
  bool _loading = false;
  // 请求令牌：并发防抖。每次提交自增，早先 in-flight 请求完成后若令牌已过期
  // 则丢弃结果，保证「后提交者胜出」且 _loading 不被旧请求提前清掉（T18-1）。
  int _req = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    if (_loading) return;
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    final service = widget.service;
    if (service == null) {
      setState(() {
        _answer = '（检索层未接线，将在 M5 完成。输入：$q）';
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
        Text(_answer),
        const SizedBox(height: 8),
        SourceList(sources: _sources),
      ],
    );
  }
}