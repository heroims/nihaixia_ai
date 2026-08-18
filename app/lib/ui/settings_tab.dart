import 'dart:async';

import 'package:flutter/material.dart';
import '../cloud/cloud_config.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});
  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _url = TextEditingController();
  final _key = TextEditingController();
  CloudConfig _cfg = const CloudConfig();

  static String? validateUrl(String? url) {
    final trimmed = (url ?? '').trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return 'Base URL 必须以 http:// 或 https:// 开头';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('云端增强（默认关闭）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('配置 OpenAI 兼容 API 后可解锁：拍照看舌象、Live 对话。'),
      const SizedBox(height: 16),
      TextField(controller: _url, decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://api.example.com/v1')),
      const SizedBox(height: 8),
      TextField(controller: _key, decoration: const InputDecoration(labelText: 'API Key')),
      const SizedBox(height: 8),
      FilledButton(onPressed: _save, child: const Text('保存')),
      if (_cfg.isEnabled)
        const Padding(padding: EdgeInsets.only(top: 8), child: Text('✅ 已启用', style: TextStyle(color: Colors.green))),
      const SizedBox(height: 8),
      const Text('API Key 明文存储于本机', style: TextStyle(fontSize: 12, color: Colors.grey)),
      const Divider(),
      const ListTile(
        leading: Icon(Icons.info),
        title: Text('关于'),
        subtitle: Text('知识库：nihaixia（MulanPSL-2.0）\n仅用于中医学习与研究'),
      ),
    ]);
  }

  void _save() {
    final error = validateUrl(_url.text);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final next = CloudConfig(baseUrl: _url.text.trim(), apiKey: _key.text.trim());
    setState(() => _cfg = next);
    unawaited(CloudConfigStore.save(next));
  }
}