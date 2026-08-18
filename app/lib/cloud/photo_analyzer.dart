// photo_analyzer.dart — 视觉模型描述舌象
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cloud_client.dart';
import 'cloud_config.dart';

/// 上传图片 base64，让视觉模型返回舌质/舌苔描述。
class PhotoAnalyzer {
  static Future<String> describeTongue(
    CloudConfig c,
    String imageBase64,
  ) async {
    final uri = Uri.parse(CloudClient.endpoint(c, 'chat/completions'));
    final body = {
      'model': c.defaultModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': '请描述这张舌象照片的舌质（颜色/胖瘦）和舌苔（色/厚薄/津液），只客观描述，不下辨证结论。'},
            // TODO(Task 23): 图片选择器将传入 mimeType，替换写死的 image/jpeg。
            {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}},
          ],
        }
      ],
    };
    final resp = await http.post(uri,
        headers: {'Authorization': 'Bearer ${c.apiKey}', 'Content-Type': 'application/json'},
        body: jsonEncode(body)).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw Exception('图片分析失败: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return CloudClient.parseContent(data);
  }
}