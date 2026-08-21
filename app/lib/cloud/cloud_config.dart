import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 远程模型缺省名。
const cloudDefaultModel = 'agnes-2.0-flash';

class CloudConfig {
  final String baseUrl; // OpenAI 兼容 endpoint，形如 .../v1
  final String apiKey;
  final String defaultModel;
  final bool enabled; // 用户总开关；关闭时保留密钥但不走云端
  const CloudConfig({
    this.baseUrl = '',
    this.apiKey = '',
    this.defaultModel = cloudDefaultModel,
    this.enabled = true,
  });

  bool get isEnabled =>
      enabled && baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;
}

/// 键值安全存储抽象：生产实现走系统 Keychain（iOS）/ Keystore（Android），
/// 测试注入内存实现。API Key 等敏感值经此存取，不落 SharedPreferences 明文。
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SystemSecureStore implements SecureStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class CloudConfigStore {
  static const _keyBase = 'cloud_base_url';
  // 历史 key：曾以明文存于 SharedPreferences；现仅用于一次性迁移读取。
  static const _legacyKeyKey = 'cloud_api_key';
  static const _keyModel = 'cloud_model';
  static const _keyEnabled = 'cloud_enabled';
  static const _secureKeyKey = 'cloud_api_key_secure';

  /// 可替换的存储后端（测试注入内存实现）。
  static SecureStore secure = SystemSecureStore();

  static Future<void> save(CloudConfig cfg) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyBase, cfg.baseUrl);
    await p.setString(_keyModel, cfg.defaultModel);
    await p.setBool(_keyEnabled, cfg.enabled);
    final key = cfg.apiKey;
    if (key.isEmpty) {
      await secure.delete(_secureKeyKey);
    } else {
      await secure.write(_secureKeyKey, key);
    }
    // 清理历史明文残留（迁移完成的旧安装）。
    await p.remove(_legacyKeyKey);
  }

  static Future<CloudConfig> load() async {
    final p = await SharedPreferences.getInstance();
    return CloudConfig(
      baseUrl: p.getString(_keyBase) ?? '',
      apiKey: await _readApiKey(p),
      defaultModel: p.getString(_keyModel) ?? cloudDefaultModel,
      enabled: p.getBool(_keyEnabled) ?? true,
    );
  }

  /// API Key 只从安全存储读；若安全存储为空且存在历史明文，
  /// 迁移进安全存储并删除明文（老版本升级路径）。
  static Future<String> _readApiKey(SharedPreferences p) async {
    final v = await secure.read(_secureKeyKey);
    if (v != null && v.isNotEmpty) return v;
    final legacy = p.getString(_legacyKeyKey);
    if (legacy != null && legacy.isNotEmpty) {
      await secure.write(_secureKeyKey, legacy);
      await p.remove(_legacyKeyKey);
      return legacy;
    }
    return '';
  }
}
