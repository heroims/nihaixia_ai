// live_chat.dart — 流式（SSE）对话
import 'cloud_client.dart';
import 'cloud_config.dart';

class LiveChat {
  /// 简单的非流式轮询（首版），流式 SSE 后续可优化。
  static Future<String> ask(CloudConfig c, String question) async {
    final messages = [
      {'role': 'system', 'content': '你是倪海厦视角的中医问答助手，回答简洁、口语化，最后建议咨询医师。'},
      {'role': 'user', 'content': question},
    ];
    return CloudClient.chat(c, messages);
  }
}
