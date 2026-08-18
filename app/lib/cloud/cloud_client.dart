import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cloud_config.dart';

class CloudClient {
  static const _timeout = Duration(seconds: 30);

  static bool isPhotoEnabled(CloudConfig c) => c.isEnabled;
  static bool isLiveEnabled(CloudConfig c) => c.isEnabled;

  static Map<String, dynamic> buildChatBody(
    CloudConfig c, {
    required List<Map<String, String>> messages,
    bool stream = false,
    String? model,
  }) {
    return {
      'model': model ?? c.defaultModel,
      'messages': messages,
      'stream': stream,
    };
  }

  static Future<String> chat(
    CloudConfig c,
    List<Map<String, String>> messages, {
    bool stream = false,
  }) async {
    final uri = Uri.parse('${c.baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions');
    final resp = await http
        .post(
          uri,
          headers: {'Authorization': 'Bearer ${c.apiKey}', 'Content-Type': 'application/json'},
          body: jsonEncode(buildChatBody(c, messages: messages, stream: stream)),
        )
        .timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('云端请求失败: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return data['choices'][0]['message']['content'] as String;
  }
}
