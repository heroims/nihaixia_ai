// app/test/cloud_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
import 'package:nihaixia_app/cloud/cloud_client.dart';

void main() {
  test('配置未设置时增强功能关闭', () {
    const cfg = CloudConfig(baseUrl: '', apiKey: '');
    expect(cfg.isEnabled, false);
    expect(CloudClient.isPhotoEnabled(cfg), false);
    expect(CloudClient.isLiveEnabled(cfg), false);
  });

  test('构造 OpenAI 兼容 chat 请求体', () {
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');
    final body = CloudClient.buildChatBody(cfg, messages: [
      {'role': 'user', 'content': '你好'},
    ], stream: false);
    expect(body['model'], 'gpt-4o-mini');
    expect(body['messages'], isA<List>());
  });
}
