enum SweatState { unknown, hasSweat, noSweat }

enum ColdState { unknown, aversionToCold, aversionToWind, aversionToHeat }

enum DiagnosisStatus { matched, insufficient, unmatched }

class SymptomInput {
  final SweatState sweat;
  final ColdState cold;
  final bool painNeck;
  final bool bodyAche;
  final bool thirst;
  final bool fever;
  const SymptomInput({
    this.sweat = SweatState.unknown,
    this.cold = ColdState.unknown,
    this.painNeck = false,
    this.bodyAche = false,
    this.thirst = false,
    this.fever = false,
  });
}

class DiagnosisResult {
  final String jing; // 六经名
  final String suggestedFormula; // 代表方方向
  final String message; // 用户提示（信息不足等）
  final List<String> sources; // 引用条文/出处
  final DiagnosisStatus status;
  const DiagnosisResult({
    this.jing = '',
    this.suggestedFormula = '',
    this.message = '',
    this.sources = const [],
    this.status = DiagnosisStatus.unmatched,
  });
}

class DiagnosticEngine {
  static const String insufficientMessage = '需要更多症状才能辨证（至少提供寒热或汗出情况）';
  static const String unmatchedMessage =
      '已根据您提供的症状匹配，暂未得出明确六经辨证，请补充其他症状（如口渴、体痛、发热）。';

  static DiagnosisResult evaluate(SymptomInput s) {
    // 完全没有提供任何信息 → insufficient
    if (s.cold == ColdState.unknown &&
        s.sweat == SweatState.unknown &&
        !s.painNeck &&
        !s.bodyAche &&
        !s.thirst &&
        !s.fever) {
      return const DiagnosisResult(
        status: DiagnosisStatus.insufficient,
        message: insufficientMessage,
      );
    }

    // 太阳中风：恶风 + 有汗 + 颈项强痛
    if (s.cold == ColdState.aversionToWind &&
        s.sweat == SweatState.hasSweat &&
        s.painNeck) {
      return const DiagnosisResult(
        status: DiagnosisStatus.matched,
        jing: '太阳病',
        suggestedFormula: '桂枝汤方向',
        sources: ['太阳病篇·条文1（总纲）', '伤寒论·第2条（太阳中风）'],
        message: '有汗恶风 → 太阳中风，桂枝汤解肌。',
      );
    }

    // 太阳伤寒：恶寒 + 无汗 + 颈项强痛/身体酸痛
    if (s.cold == ColdState.aversionToCold &&
        s.sweat == SweatState.noSweat &&
        (s.painNeck || s.bodyAche)) {
      return const DiagnosisResult(
        status: DiagnosisStatus.matched,
        jing: '太阳病',
        suggestedFormula: '麻黄汤方向',
        sources: ['太阳病篇·条文1（总纲）', '伤寒论·第3条（太阳伤寒）'],
        message: '无汗恶寒、体痛 → 太阳伤寒，麻黄汤发汗。',
      );
    }

    // 提供了信息但未匹配到规则 → unmatched（如实告知，不臆造辨证）
    return const DiagnosisResult(
      status: DiagnosisStatus.unmatched,
      message: unmatchedMessage,
    );
  }
}
