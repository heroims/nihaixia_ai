import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'cloud_config.dart';

class CloudClient {
  static const _timeout = Duration(seconds: 30);

  static bool isPhotoEnabled(CloudConfig c) => c.isEnabled;
  static bool isLiveEnabled(CloudConfig c) => c.isEnabled;

  /// 拼接 OpenAI 兼容 endpoint：去 baseUrl 尾部斜杠后追加 path。
  static String endpoint(CloudConfig c, String path) {
    final base = c.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/${path.replaceAll(RegExp(r'^/+'), '')}';
  }

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
    final uri = Uri.parse(endpoint(c, 'chat/completions'));
    final http.Response resp;
    try {
      resp = await http
          .post(
            uri,
            headers: {'Authorization': 'Bearer ${c.apiKey}', 'Content-Type': 'application/json'},
            body: jsonEncode(buildChatBody(c, messages: messages, stream: stream)),
          )
          .timeout(_timeout);
    } on SocketException catch (e) {
      throw Exception('网络连接失败，请检查网络设置（$e）');
    } on TimeoutException catch (e) {
      throw Exception('网络连接超时，请稍后重试（$e）');
    } on http.ClientException catch (e) {
      throw Exception('网络请求异常，请检查网络设置（$e）');
    }
    if (resp.statusCode != 200) {
      throw Exception('云端请求失败: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return parseContent(data);
  }

  /// 稳健解析 choices[0].message.content：error 形态、非 List choices、
  /// 缺失/非字符串 content 均抛出带错误信息的干净异常。
  static String parseContent(Map<String, dynamic> data) {
    final errorMsg = (data['error'] as Map?)?.isNotEmpty == true
        ? (data['error'] as Map)['message']
        : null;
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final content = (choices.first as Map?)?['message']?['content'];
      if (content is String && content.isNotEmpty) {
        return content;
      }
    }
    final detail = errorMsg == null ? '' : '：$errorMsg';
    throw Exception('云端返回内容解析失败$detail');
  }
}