import 'package:shared_preferences/shared_preferences.dart';

class CloudConfig {
  final String baseUrl; // OpenAI 兼容 endpoint，形如 .../v1
  final String apiKey;
  final String defaultModel;
  final bool enabled; // 用户总开关；关闭时保留密钥但不走云端
  const CloudConfig({
    this.baseUrl = '',
    this.apiKey = '',
    this.defaultModel = 'gpt-4o-mini',
    this.enabled = true,
  });

  bool get isEnabled =>
      enabled && baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;
}

class CloudConfigStore {
  static const _keyBase = 'cloud_base_url';
  static const _keyKey = 'cloud_api_key';
  static const _keyModel = 'cloud_model';
  static const _keyEnabled = 'cloud_enabled';

  static Future<void> save(CloudConfig cfg) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyBase, cfg.baseUrl);
    await p.setString(_keyKey, cfg.apiKey);
    await p.setString(_keyModel, cfg.defaultModel);
    await p.setBool(_keyEnabled, cfg.enabled);
  }

  static Future<CloudConfig> load() async {
    final p = await SharedPreferences.getInstance();
    return CloudConfig(
      baseUrl: p.getString(_keyBase) ?? '',
      apiKey: p.getString(_keyKey) ?? '',
      defaultModel: p.getString(_keyModel) ?? 'gpt-4o-mini',
      enabled: p.getBool(_keyEnabled) ?? true,
    );
  }
}
