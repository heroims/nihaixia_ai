import 'package:flutter/material.dart';

const _emergencyKeywords = ['胸痛', '呼吸困难', '呕血', '昏迷', '高热不退', '剧烈腹痛', '抽搐'];

class WarningCard extends StatelessWidget {
  final String? text;
  const WarningCard({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    final matched = text == null
        ? <String>[]
        : _emergencyKeywords.where(text!.contains).toList();
    if (matched.isEmpty) return const SizedBox.shrink();
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text('⚠ 检测到急危重症相关词（${matched.join('、')}），请立即就医。',
            style: TextStyle(color: Colors.red.shade800)),
      ),
    );
  }
}