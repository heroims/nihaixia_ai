// app/integration_test/cloud_smoke_test.dart
// 云端增强冒烟测试：从真机/模拟器经真实 http 栈请求 OpenAI 兼容 endpoint。
// 运行前先在本机启动 mock 服务器（10.0.2.2 是模拟器访问宿主机的别名）：
//   python3 tools/mock_openai_server.py 8765
// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nihaixia_app/cloud/cloud_client.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('云端 chat 全链路（明文 http + 解析）', (tester) async {
    const cfg = CloudConfig(
      baseUrl: 'http://10.0.2.2:8765/v1',
      apiKey: 'test-key',
      defaultModel: 'mock-model',
    );
    expect(cfg.isEnabled, isTrue);

    final out = await CloudClient.chat(cfg, [
      {'role': 'user', 'content': '你好'},
    ]);
    print('[cloud-smoke] output=$out');
    expect(out, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
