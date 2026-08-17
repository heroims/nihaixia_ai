import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/retrieval/structured_queries.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('findHerbs', () {
    test('现代名桂枝经别名命中古名牡桂', () async {
      await db.into(db.herbs).insert(HerbsCompanion.insert(
            name: '牡桂',
            taste: const Value('辛温'),
            indications: const Value('解肌发表'),
          ));

      final rows = await StructuredQueries.findHerbs(db, '桂枝');

      expect(rows, isNotEmpty);
      expect(rows.first.name, '牡桂');
    });

    test('古名牡桂直接命中', () async {
      await db.into(db.herbs).insert(HerbsCompanion.insert(name: '牡桂'));

      final rows = await StructuredQueries.findHerbs(db, '牡桂');

      expect(rows, isNotEmpty);
      expect(rows.first.name, '牡桂');
    });

    test('单字子串命中多个含字条目', () async {
      await db.into(db.herbs).insert(HerbsCompanion.insert(name: '牡桂'));
      await db.into(db.herbs).insert(HerbsCompanion.insert(name: '菌桂'));

      final rows = await StructuredQueries.findHerbs(db, '桂');

      expect(rows.map((h) => h.name), containsAll(['牡桂', '菌桂']));
    });
  });

  group('findTiaoWen', () {
    test('命中正文含关键字条文', () async {
      await db.into(db.tiaoWen).insert(TiaoWenCompanion.insert(
            number: const Value('1'),
            title: const Value('太阳病提纲'),
            body: const Value('太阳之为病，脉浮，头项强痛而恶寒。'),
            formulaHint: const Value(''),
            source: const Value('伤寒论'),
          ));

      final rows = await StructuredQueries.findTiaoWen(db, '恶寒');

      expect(rows, isNotEmpty);
      expect(rows.first.body, contains('恶寒'));
    });

    test('空 body 条文回退标题匹配', () async {
      await db.into(db.tiaoWen).insert(TiaoWenCompanion.insert(
            number: const Value('1'),
            title: const Value('太阳之为病，脉浮，头项强痛而恶寒'),
            body: const Value(''),
            formulaHint: const Value(''),
            source: const Value('伤寒论'),
          ));

      final rows = await StructuredQueries.findTiaoWen(db, '恶寒');

      expect(rows, isNotEmpty);
      expect(rows.first.title, contains('恶寒'));
    });
  });

  group('findCases', () {
    test('命中正文含关键字医案', () async {
      await db.into(db.cases).insert(CasesCompanion.insert(
            title: const Value('乳癌案'),
            body: const Value('某女，确诊乳癌，化疗后乏力。'),
            source: const Value('医案集'),
          ));

      final rows = await StructuredQueries.findCases(db, '乳癌');

      expect(rows, isNotEmpty);
      expect(rows.first.body, contains('乳癌'));
    });
  });

  group('findFormulas', () {
    test('命中方名', () async {
      await db.into(db.formulas).insert(FormulasCompanion.insert(
            name: const Value('桂枝汤'),
            title: const Value('桂枝汤'),
            keySymptoms: const Value('太阳中风，头痛发热'),
          ));

      final rows = await StructuredQueries.findFormulas(db, '桂枝');

      expect(rows, isNotEmpty);
      expect(rows.first.name, '桂枝汤');
    });

    test('命中 key_symptoms', () async {
      await db.into(db.formulas).insert(FormulasCompanion.insert(
            name: const Value('麻黄汤'),
            title: const Value('麻黄汤'),
            keySymptoms: const Value('恶寒发热，无汗而喘'),
          ));

      final rows = await StructuredQueries.findFormulas(db, '恶寒');

      expect(rows, isNotEmpty);
    });
  });

  test('无命中返回空列表', () async {
    expect(await StructuredQueries.findHerbs(db, '不存在的药'), isEmpty);
    expect(await StructuredQueries.findTiaoWen(db, '不存在的词'), isEmpty);
    expect(await StructuredQueries.findCases(db, '不存在的词'), isEmpty);
    expect(await StructuredQueries.findFormulas(db, '不存在的词'), isEmpty);
  });
}