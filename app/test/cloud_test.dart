// app/test/cloud_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
import 'package:nihaixia_app/cloud/cloud_client.dart';

void main() {
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
    expect(body['model'], 'gpt-4o-mini');
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
}