class AnswerAssembler {
  /// 空答案文案（检索无命中 / 命中但无正文时的统一降级语义）。
  static String formatEmpty() => '资料中未找到相关内容。';

  /// 纯文本出处拼接工具。QA 主链路不使用本方法：QaResult.sources 结构性承载
  /// 出处，QaTab 用 SourceList 渲染，不再把（来源）内嵌进 answer 字符串（T18-4）。
  /// 保留作通用工具，供非 RAG 上下文直接渲染「来源字符串」用（Task 21+）。
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