// app/test/retrieval_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/retrieval/intent_router.dart';
import 'package:nihaixia_app/retrieval/synonyms.dart';
import 'package:nihaixia_app/retrieval/answer_assembler.dart';

void main() {
  group('intent router', () {
    test('识别方剂查询', () {
      expect(IntentRouter.classify('小柴胡汤什么时候用'), Intent.herbFormula);
    });
    test('识别症状辨证', () {
      expect(IntentRouter.classify('我感冒了怕冷没汗'), Intent.diagnosis);
    });
    test('识别药物', () {
      expect(IntentRouter.classify('生附子和炮附子的区别'), Intent.herbFormula);
    });
    test('无法识别回退 general', () {
      expect(IntentRouter.classify('你好呀'), Intent.general);
    });
  test('识别高频症状查询', () {
      expect(IntentRouter.classify('咳嗽怎么治'), Intent.diagnosis);
    });
    test('识别症状口语别名', () {
      expect(IntentRouter.classify('拉肚子'), Intent.diagnosis);
    });
  });

  group('synonyms', () {
    test('别名归正', () {
      expect(Synonyms.canonicalize('柴胡汤'), '小柴胡汤');
    });
    test('部分名不叠加替换', () {
      expect(Synonyms.canonicalize('小柴胡汤'), '小柴胡汤');
      expect(Synonyms.canonicalize('大柴胡汤'), '大柴胡汤');
    });
    test('无别名原样返回', () {
      expect(Synonyms.canonicalize('桂枝汤'), '桂枝汤');
    });
  });

  group('answer assembler', () {
    test('无证据时提示资料不足', () {
      final out = AnswerAssembler.formatEmpty();
      expect(out, contains('资料中未找到'));
    });
    test('有证据时拼接出处', () {
      final out = AnswerAssembler.formatSnippet(
        sources: ['伤寒论·第1条', '金匮·卒病'],
      );
      expect(out, contains('伤寒论'));
      expect(out, contains('（来源）'));
    });
  });
}