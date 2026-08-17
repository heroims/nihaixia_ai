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
      expect(r.status, DiagnosisStatus.matched);
      expect(r.jing, '太阳病');
      expect(r.suggestedFormula, contains('麻黄汤'));
    });

    test('有汗恶风 → 太阳中风', () {
      final r = DiagnosticEngine.evaluate(const SymptomInput(
        sweat: SweatState.hasSweat,
        cold: ColdState.aversionToWind,
        painNeck: true,
      ));
      expect(r.status, DiagnosisStatus.matched);
      expect(r.jing, '太阳病');
      expect(r.suggestedFormula, contains('桂枝汤'));
    });

    test('恶风 + 无汗不匹配太阳伤寒', () {
      final r = DiagnosticEngine.evaluate(const SymptomInput(
        sweat: SweatState.noSweat,
        cold: ColdState.aversionToWind,
        painNeck: true,
      ));
      expect(r.status, DiagnosisStatus.unmatched);
      expect(r.jing, isEmpty);
      expect(r.suggestedFormula, isEmpty);
    });

    test('怕冷 + 有汗（混合）不匹配太阳中风', () {
      final r = DiagnosticEngine.evaluate(const SymptomInput(
        sweat: SweatState.hasSweat,
        cold: ColdState.aversionToCold,
        painNeck: true,
      ));
      expect(r.status, DiagnosisStatus.unmatched);
      expect(r.jing, isEmpty);
      expect(r.message, isNot(contains('太阳中风')));
      expect(r.message, isNot(contains('恶风')));
    });

    test('怕热 + 无汗 + 颈项痛 → unmatched 而非误匹配', () {
      final r = DiagnosticEngine.evaluate(const SymptomInput(
        sweat: SweatState.noSweat,
        cold: ColdState.aversionToHeat,
        painNeck: true,
      ));
      expect(r.status, DiagnosisStatus.unmatched);
      expect(r.jing, isEmpty);
      expect(r.suggestedFormula, isEmpty);
    });

    test('仅有发热（半信息）→ unmatched 且提示不误导', () {
      final r = DiagnosticEngine.evaluate(const SymptomInput(fever: true));
      expect(r.status, DiagnosisStatus.unmatched);
      expect(r.jing, isEmpty);
      expect(r.message, isNot(contains('需要更多症状才能辨证')));
      expect(r.message, contains('暂未得出明确六经辨证'));
    });
  });

  test('信息不足时提示需更多症状', () {
    final r = DiagnosticEngine.evaluate(const SymptomInput());
    expect(r.status, DiagnosisStatus.insufficient);
    expect(r.jing, isEmpty);
    expect(r.message, contains('需要更多症状'));
  });

  test('unmatched 默认状态（无规则命中且未提供信息视为 insufficient 覆盖）', () {
    expect(const DiagnosisResult().status, DiagnosisStatus.unmatched);
  });
}