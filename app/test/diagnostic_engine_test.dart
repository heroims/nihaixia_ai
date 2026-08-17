import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/rules/diagnostic_engine.dart';

void main() {
  group('太阳病规则', () {
    test('无汗恶寒体痛 → 太阳伤寒', () {
      final r = DiagnosticEngine.evaluate(const SymptomInput(
        sweat: SweatState.noSweat,
        cold: ColdState.aversionToCold,
        painNeck: true,
      ));
      expect(r.jing, '太阳病');
      expect(r.suggestedFormula, contains('麻黄汤'));
    });

    test('有汗恶风 → 太阳中风', () {
      final r = DiagnosticEngine.evaluate(const SymptomInput(
        sweat: SweatState.hasSweat,
        cold: ColdState.aversionToWind,
        painNeck: true,
      ));
      expect(r.jing, '太阳病');
      expect(r.suggestedFormula, contains('桂枝汤'));
    });
  });

  test('信息不足时提示需更多症状', () {
    final r = DiagnosticEngine.evaluate(const SymptomInput());
    expect(r.jing, isEmpty);
    expect(r.message, contains('需要更多症状'));
  });
}
