import 'package:flutter/material.dart';
import 'package:nihaixia_app/core/models.dart';

/// 结构化出处列表：渲染 [SearchHit] 的 source·heading，空列表渲染为空。
class SourceList extends StatelessWidget {
  final List<SearchHit> sources;
  const SourceList({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('（来源）', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final s in sources.take(5))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: InkWell(
              onTap: () {},
              child: Text(
                '· ${s.source}·${s.heading}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ),
      ],
    );
  }
}
