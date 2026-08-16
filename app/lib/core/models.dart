/// 检索结果模型：一条命中的原文片段。
class SearchHit {
  final String source;
  final String heading;
  final String text;

  const SearchHit({
    required this.source,
    required this.heading,
    required this.text,
  });
}