import 'dart:async';

import 'package:flutter/material.dart';
import '../cloud/cloud_config.dart';
import '../llm/inference_settings.dart';
import '../llm/local_model_state.dart';
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

  @override
  void initState() {
    super.initState();
    unawaited(_loadSaved());
  }

  Future<void> _loadSaved() async {
    try {
      await InferenceSettings.instance.load();
      await LocalModelState.instance.refreshInstalled();
      final cfg = await CloudConfigStore.load();
      if (!mounted) return;
      setState(() {
        _cfg = cfg;
        _mode = InferenceSettings.instance.mode;
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
      // 端侧模型真实加载状态：由问答页预热驱动，此处监听展示。
      ListenableBuilder(
        listenable: LocalModelState.instance,
        builder: (context, _) {
          final s = LocalModelState.instance;
          final (status, icon, color) = switch (s.phase) {
            LocalModelPhase.checking => ('检查中…', Icons.help_outline, Colors.grey),
            LocalModelPhase.notInstalled => ('未安装', Icons.error_outline, Colors.orange),
            LocalModelPhase.installedNotLoaded => ('已安装，未加载', Icons.schedule, Colors.grey),
            LocalModelPhase.loading => ('加载中…', Icons.downloading, Colors.blue),
            LocalModelPhase.loaded => ('已加载，可离线问答', Icons.check_circle, Colors.green),
            LocalModelPhase.failed => ('加载失败', Icons.error, Colors.red),
          };
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.memory),
            title: Text('端侧模型：${LlmModelResolver.modelDisplayName}'),
            subtitle: Text(s.phase == LocalModelPhase.failed && s.detail != null
                ? '$status：${s.detail}'
                : status),
            trailing: Icon(icon, color: color),
          );
        },
      ),
      const Divider(),
      // 云端配置区：是否使用云端完全由上方推理模式决定（唯一真相源），
      // 此处只负责填写/保存连接配置，不再有独立启用开关。
      ListenableBuilder(
        listenable: InferenceSettings.instance,
        builder: (context, _) {
          final cloudActive = InferenceSettings.instance.mode ==
              InferenceMode.cloudFirst;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('云端连接（${cloudActive ? "当前模式使用云端" : "当前模式不使用云端"}）',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                cloudActive
                    ? '「云端优先」模式：问答优先走云端，失败自动落回端侧/检索。填好下方配置即可生效。'
                    : '当前为「${InferenceSettings.instance.mode.label}」模式，问答不走云端；配置保留，切回「云端优先」后自动生效。配置齐全还可解锁拍照看舌象、Live 对话。',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      TextField(controller: _url, decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://api.example.com/v1')),
      const SizedBox(height: 8),
      TextField(controller: _key, obscureText: true, decoration: const InputDecoration(labelText: 'API Key')),
      const SizedBox(height: 8),
      TextField(controller: _model, decoration: const InputDecoration(labelText: '模型名', hintText: cloudDefaultModel)),
      const SizedBox(height: 8),
      FilledButton(onPressed: _save, child: const Text('保存')),
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

  /// 保存表单：只写连接配置，不触碰任何启用语义（是否走云端由推理模式决定）。
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
      enabled: _cfg.enabled, // 遗留字段原样保留，不再驱动任何行为
    );
    setState(() => _cfg = next);
    unawaited(CloudConfigStore.save(next));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
  }
}
