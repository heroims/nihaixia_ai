import 'package:flutter/material.dart';

class SourceList extends StatelessWidget {
  final List<String> sources;
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
              child: Text('· $s', style: const TextStyle(color: Colors.blue)),
            ),
          ),
      ],
    );
  }
}