// app/lib/llm/prompt_templates.dart
class PromptTemplates {
  static String rag({required String question, required List<String> evidences}) {
    final buf = StringBuffer()
      ..writeln('你是倪海厦经方中医助手。请仅基于以下资料回答问题。')
      ..writeln('不要编造资料中不存在的内容。')
      ..writeln()
      ..writeln('【资料】');
    for (final e in evidences.take(8)) {
      buf.writeln('- $e');
    }
    buf
      ..writeln()
      ..writeln('【问题】$question')
      ..writeln()
      ..writeln(
          '要求：1) 只依据资料回答 2) 结尾注明出处 3) 资料不足时明确说"资料中未找到" 4) 内容仅供学习参考，不构成医疗建议，身体不适请及时就医。');
    return buf.toString();
  }
}
