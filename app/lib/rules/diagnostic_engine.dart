enum SweatState { unknown, hasSweat, noSweat }
enum ColdState { unknown, aversionToCold, aversionToWind, aversionToHeat }

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
  final String jing;      // 六经名
  final String suggestedFormula; // 代表方方向
  final String message;   // 用户提示（信息不足等）
  final List<String> sources; // 引用条文/出处
  const DiagnosisResult({
    this.jing = '',
    this.suggestedFormula = '',
    this.message = '',
    this.sources = const [],
  });
}

class DiagnosticEngine {
  static DiagnosisResult evaluate(SymptomInput s) {
    if (s.cold == ColdState.unknown && s.sweat == SweatState.unknown) {
      return const DiagnosisResult(message: '需要更多症状才能辨证（至少提供寒热或汗出情况）');
    }

    // 太阳病
    if ((s.cold == ColdState.aversionToCold || s.cold == ColdState.aversionToWind) &&
        s.painNeck) {
      if (s.sweat == SweatState.hasSweat) {
        return const DiagnosisResult(
          jing: '太阳病',
          suggestedFormula: '桂枝汤方向',
          sources: ['伤寒论·太阳病提纲', '伤寒论·第2条（太阳中风）'],
          message: '有汗恶风 → 太阳中风，桂枝汤解肌。',
        );
      }
      if (s.sweat == SweatState.noSweat) {
        return const DiagnosisResult(
          jing: '太阳病',
          suggestedFormula: '麻黄汤方向',
          sources: ['伤寒论·太阳病提纲', '伤寒论·第3条（太阳伤寒）'],
          message: '无汗恶寒、体痛 → 太阳伤寒，麻黄汤发汗。',
        );
      }
    }
    return const DiagnosisResult(message: '尚未匹配到明确辨证，请补充更多症状。');
  }
}
