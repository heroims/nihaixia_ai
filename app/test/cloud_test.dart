// app/test/cloud_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
import 'package:nihaixia_app/cloud/cloud_client.dart';

/// 内存版安全存储：单测注入 CloudConfigStore.secure。
class InMemorySecureStore implements SecureStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  late InMemorySecureStore secure;

  setUp(() {
    secure = InMemorySecureStore();
    CloudConfigStore.secure = secure;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    CloudConfigStore.secure = SystemSecureStore();
  });

  test('配置未设置时增强功能关闭', () {
    const cfg = CloudConfig(baseUrl: '', apiKey: '');
    expect(cfg.isEnabled, false);
    expect(CloudClient.isPhotoEnabled(cfg), false);
    expect(CloudClient.isLiveEnabled(cfg), false);
  });

  test('配置已设置时增强功能开启', () {
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');
    expect(CloudClient.isPhotoEnabled(cfg), true);
    expect(CloudClient.isLiveEnabled(cfg), true);
  });

  test('构造 OpenAI 兼容 chat 请求体', () {
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');
    final body = CloudClient.buildChatBody(cfg, messages: [
      {'role': 'user', 'content': '你好'},
    ], stream: false);
    expect(body['model'], 'agnes-2.0-flash');
    expect(body['messages'], isA<List>());
  });

  test('buildChatBody 支持自定义 model 覆盖', () {
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');
    final body = CloudClient.buildChatBody(cfg,
        messages: [{'role': 'user', 'content': '你好'}], model: 'custom-model');
    expect(body['model'], 'custom-model');
  });

  test('endpoint 拼接去尾部/首部斜杠', () {
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1///', apiKey: 'k');
    expect(CloudClient.endpoint(cfg, 'chat/completions'), 'https://api.example.com/v1/chat/completions');
    expect(CloudClient.endpoint(cfg, '/chat/completions'), 'https://api.example.com/v1/chat/completions');
  });

  test('CloudConfigStore 保存加载字段完整往返', () async {
    SharedPreferences.setMockInitialValues({});
    const cfg = CloudConfig(
      baseUrl: 'https://api.example.com/v1',
      apiKey: 'secret-key',
      defaultModel: 'gpt-4o',
    );
    await CloudConfigStore.save(cfg);
    final loaded = await CloudConfigStore.load();
    expect(loaded.baseUrl, cfg.baseUrl);
    expect(loaded.apiKey, cfg.apiKey);
    expect(loaded.defaultModel, cfg.defaultModel);
  });

  test('遗留 enabled 字段仅影响 isEnabled，不再门控拍照/Live（模式为唯一真相源）', () {
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k', enabled: false);
    expect(cfg.isEnabled, false);
    // 拍照/Live 只看配置是否齐全；是否走云端问答由推理模式决定。
    expect(CloudClient.isPhotoEnabled(cfg), true);
    expect(CloudClient.isLiveEnabled(cfg), true);

    const unconfigured = CloudConfig(baseUrl: '', apiKey: '', enabled: true);
    expect(unconfigured.isEnabled, false);
    expect(CloudClient.isPhotoEnabled(unconfigured), false);
    expect(CloudClient.isLiveEnabled(unconfigured), false);
  });

  test('enabled 开关持久化往返（关闭后重载仍关闭）', () async {
    SharedPreferences.setMockInitialValues({});
    const on = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');
    await CloudConfigStore.save(on);
    expect((await CloudConfigStore.load()).isEnabled, true);

    const off = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k', enabled: false);
    await CloudConfigStore.save(off);
    final reloaded = await CloudConfigStore.load();
    expect(reloaded.enabled, false);
    expect(reloaded.apiKey, 'k'); // 密钥保留，不清空
    expect(reloaded.isEnabled, false);
  });

  test('API Key 存入安全存储而非 SharedPreferences 明文', () async {
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'secret-key');
    await CloudConfigStore.save(cfg);
    // 安全存储里有。
    expect(secure.values['cloud_api_key_secure'], 'secret-key');
    // SharedPreferences 里没有明文残留。
    final p = await SharedPreferences.getInstance();
    expect(p.getString('cloud_api_key'), isNull);
    final loaded = await CloudConfigStore.load();
    expect(loaded.apiKey, 'secret-key');
  });

  test('历史明文 API Key 自动迁移进安全存储并删除明文', () async {
    SharedPreferences.setMockInitialValues({'cloud_api_key': 'legacy-plain'});
    final loaded = await CloudConfigStore.load();
    expect(loaded.apiKey, 'legacy-plain');
    expect(secure.values['cloud_api_key_secure'], 'legacy-plain');
    final p = await SharedPreferences.getInstance();
    expect(p.getString('cloud_api_key'), isNull); // 明文已清除
  });

  test('未配置时默认模型为 agnes-2.0-flash', () async {
    final loaded = await CloudConfigStore.load();
    expect(loaded.defaultModel, 'agnes-2.0-flash');
  });

  test('apiKey 为空保存时清空安全存储', () async {
    secure.values['cloud_api_key_secure'] = 'old';
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: '');
    await CloudConfigStore.save(cfg);
    expect(secure.values.containsKey('cloud_api_key_secure'), false);
    expect((await CloudConfigStore.load()).apiKey, '');
  });
}