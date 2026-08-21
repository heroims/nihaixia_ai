import 'dart:async';

import 'package:flutter/material.dart';
import '../cloud/cloud_config.dart';
import '../llm/inference_settings.dart';
import '../llm/model_resolver.dart';

String? validateCloudUrl(String? url) {
  final trimmed = (url ?? '').trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      !(uri.isScheme('http') || uri.isScheme('https')) ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      RegExp(r'\s').hasMatch(trimmed)) {
    return 'Base URL 必须以 http:// 或 https:// 开头';
  }
  return null;
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});
  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _url = TextEditingController();
  final _key = TextEditingController();
  final _model = TextEditingController();
  CloudConfig _cfg = const CloudConfig();
  InferenceMode _mode = InferenceMode.cloudFirst;
  bool _localModelReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSaved());
  }

  Future<void> _loadSaved() async {
    try {
      await InferenceSettings.instance.load();
      final cfg = await CloudConfigStore.load();
      final ready = await LlmModelResolver.isInstalled();
      if (!mounted) return;
      setState(() {
        _cfg = cfg;
        _mode = InferenceSettings.instance.mode;
        _localModelReady = ready;
        _url.text = cfg.baseUrl;
        _key.text = cfg.apiKey;
        _model.text = cfg.defaultModel;
      });
    } catch (e) {
      debugPrint('settings load failed: $e');
    }
  }

  /// 切换推理模式：持久化并通知问答页重新接线。
  Future<void> _changeMode(InferenceMode m) async {
    setState(() => _mode = m);
    await InferenceSettings.instance.setMode(m);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已切换为「${m.label}」模式')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('推理模式', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      SegmentedButton<InferenceMode>(
        segments: [
          for (final m in InferenceMode.values)
            ButtonSegment(value: m, label: Text(m.label)),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => unawaited(_changeMode(s.first)),
      ),
      const SizedBox(height: 4),
      Text(_modeHint(_mode), style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 8),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.memory),
        title: Text('端侧模型：${LlmModelResolver.modelDisplayName}'),
        subtitle: Text(_localModelReady ? '已就绪（离线可用）' : '未安装'),
        trailing: Icon(
          _localModelReady ? Icons.check_circle : Icons.error_outline,
          color: _localModelReady ? Colors.green : Colors.orange,
        ),
      ),
      const Divider(),
      const Text('云端增强（默认关闭）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('配置 OpenAI 兼容 API 后可解锁：拍照看舌象、Live 对话。'),
      const SizedBox(height: 16),
      TextField(controller: _url, decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://api.example.com/v1')),
      const SizedBox(height: 8),
      TextField(controller: _key, obscureText: true, decoration: const InputDecoration(labelText: 'API Key')),
      const SizedBox(height: 8),
      TextField(controller: _model, decoration: const InputDecoration(labelText: '模型名', hintText: cloudDefaultModel)),
      const SizedBox(height: 8),
      FilledButton(onPressed: _save, child: const Text('保存')),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('启用云端增强'),
        subtitle: Text(_cfg.isEnabled ? '已启用（问答/拍照将优先走云端）' : '已关闭（仅使用端侧模型）'),
        value: _cfg.isEnabled,
        onChanged: (v) => _toggleEnabled(v),
      ),
      const SizedBox(height: 8),
      const Text('API Key 加密存储于本机（iOS Keychain / Android Keystore）',
          style: TextStyle(fontSize: 12, color: Colors.grey)),
      const Divider(),
      const ListTile(
        leading: Icon(Icons.info),
        title: Text('关于'),
        subtitle: Text('知识库：nihaixia（MulanPSL-2.0）\n仅用于中医学习与研究'),
      ),
    ]);
  }

  static String _modeHint(InferenceMode m) => switch (m) {
        InferenceMode.retrievalOnly => '直接返回知识库原文，无需任何模型，响应最快。',
        InferenceMode.localLlm => '使用内置端侧模型归纳回答，完全离线。',
        InferenceMode.cloudFirst => '优先云端模型，失败自动落回端侧/检索。',
      };

  /// 开关只切换启用状态，不清空已填的 URL/Key/模型名。
  void _toggleEnabled(bool v) {
    final model = _model.text.trim();
    final next = CloudConfig(
      baseUrl: _url.text.trim(),
      apiKey: _key.text.trim(),
      defaultModel: model.isEmpty ? cloudDefaultModel : model,
      enabled: v,
    );
    setState(() => _cfg = next);
    unawaited(CloudConfigStore.save(next));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(v ? '云端增强已启用' : '云端增强已关闭')));
  }

  void _save() {
    final error = validateCloudUrl(_url.text);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final model = _model.text.trim();
    final next = CloudConfig(
      baseUrl: _url.text.trim(),
      apiKey: _key.text.trim(),
      defaultModel: model.isEmpty ? cloudDefaultModel : model,
      // 保留当前开关状态：保存表单不应隐式改变启用开关。
      enabled: _cfg.enabled,
    );
    setState(() => _cfg = next);
    unawaited(CloudConfigStore.save(next));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
  }
}
