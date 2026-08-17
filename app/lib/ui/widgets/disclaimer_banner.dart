import 'package:flutter/material.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.all(8),
      child: const Text(
        '本 App 为倪海厦中医教学知识整理，仅供学习参考，不构成医疗建议。'
        '如有急症或不适，请立即就医。',
        style: TextStyle(fontSize: 12, color: Colors.brown),
      ),
    );
  }
}