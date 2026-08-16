class AnswerAssembler {
  static String formatEmpty() => '资料中未找到相关内容。';

  static String formatSnippet({
    required List<String> sources,
    String? answer,
  }) {
    final buf = StringBuffer();
    if (answer != null && answer.isNotEmpty) buf.write(answer);
    buf.writeln();
    buf.writeln();
    buf.writeln('（来源）');
    for (final s in sources.take(5)) {
      buf.writeln('· $s');
    }
    return buf.toString();
  }
}