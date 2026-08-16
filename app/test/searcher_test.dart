import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/core/models.dart';
import 'package:nihaixia_app/retrieval/query_terms.dart';
import 'package:nihaixia_app/retrieval/searcher.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> insert(String content, {String source = '', String heading = ''}) {
    return db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: Value(source),
          heading: Value(heading),
          content: content,
        ));
  }

  group('searchRawChunks', () {
    test('substring search returns matching chunk', () async {
      await insert('太阳之为病，脉浮，头项强痛而恶寒。',
          source: '伤寒论', heading: '第1条');
      await insert('夫治未病者，见肝之病，知肝传脾。',
          source: '金匮', heading: '卒病');

      final res = await Searcher.searchRawChunks(db, ['恶寒']);

      expect(res, isNotEmpty);
      expect(res.first.text, contains('恶寒'));
      expect(res.first.source, '伤寒论');
      expect(res.first.heading, '第1条');
    });

    test('multiword AND requires all words', () async {
      await insert('太阳之为病，脉浮，头项强痛而恶寒。');
      await insert('太阳之为病，脉浮。');

      final res = await Searcher.searchRawChunks(db, ['脉浮', '恶寒']);

      expect(res, hasLength(1));
      expect(res.single.text, contains('恶寒'));
    });

    test('no match returns empty', () async {
      await insert('太阳之为病，脉浮，头项强痛而恶寒。');

      expect(await Searcher.searchRawChunks(db, ['不存在的词']), isEmpty);
    });

    test('empty andTerms/orTerms returns empty', () async {
      await insert('太阳之为病，脉浮。');

      expect(await Searcher.searchRawChunks(db, const []), isEmpty);
    });

    test('results ranked by occurrence count', () async {
      await insert('桂枝，桂枝，桂枝，善治感冒。');
      await insert('桂枝汤主治太阳中风。');

      final res = await Searcher.searchRawChunks(db, ['桂枝']);

      expect(res, hasLength(2));
      expect(res.first.text, contains('桂枝，桂枝，桂枝'));
    });

    test('orTerms only add score, not filter', () async {
      await insert('太阳之为病，脉浮，头项强痛而恶寒。', source: '甲');
      await insert('恶寒发热者，发于阳也。', source: '乙');

      final res = await Searcher.searchRawChunks(db, ['恶寒'],
          orTerms: ['脉浮', '项强']);

      expect(res, hasLength(2));
      expect(res.first.source, '甲');
    });

    test('LIKE wildcard underscore is escaped', () async {
      await insert('太阳之为病，脉浮，头项强痛而恶寒。');
      await insert('恶寒发热者，发于阳也。');

      // 未转义时 '恶_寒' 的 _ 会当单字符通配符命中「恶寒」行。
      final res = await Searcher.searchRawChunks(db, ['恶_寒']);

      expect(res, isEmpty);
    });

    test('LIKE wildcard percent is escaped', () async {
      await insert('桂枝汤主治太阳中风。');
      await insert('临床有效率 100% 的对照组。');

      // 未转义时 '%' 会当任意串通配符命中所有行。
      final res = await Searcher.searchRawChunks(db, ['%']);

      expect(res, hasLength(1));
      expect(res.single.text, contains('%'));
    });

    test('distilled source outranks same-content generic row', () async {
      const content = '桂枝汤主治太阳中风，脉浮缓。';
      await insert(content, source: '01-six-meridian-formulas.md');
      await insert(content, source: '通用');

      final res = await Searcher.searchRawChunks(db, ['桂枝']);

      expect(res, hasLength(2));
      expect(res.first.source, '01-six-meridian-formulas.md');
    });

    test('yian case bonus is lower than distilled bonus', () async {
      const content = '桂枝汤主治太阳中风，脉浮缓。';
      await insert(content, source: '医案集');
      await insert(content, source: '03-clinical-experience.md');

      final res = await Searcher.searchRawChunks(db, ['桂枝']);

      expect(res.first.source, '03-clinical-experience.md');
    });

    test('ranking stable with more matches than limit', () async {
      for (var i = 0; i < 10; i++) {
        await insert('桂枝' * (i + 1));
      }

      final res = await Searcher.searchRawChunks(db, ['桂枝'], limit: 5);

      expect(res, hasLength(5));
      expect(res.first.text, contains('桂枝' * 10));
    });

    test('returns SearchHit model', () async {
      await insert('太阳之为病，脉浮，头项强痛而恶寒。',
          source: '伤寒论', heading: '第1条');

      final res = await Searcher.searchRawChunks(db, ['恶寒']);

      expect(res.first, isA<SearchHit>());
      expect(res.first.source, '伤寒论');
      expect(res.first.heading, '第1条');
      expect(res.first.text, isNotEmpty);
    });
  });

  group('searchByQuery', () {
    test('no-space CJK query with vocabulary terms recalls matching chunk',
        () async {
      await insert('风寒感冒，怕冷无汗，头痛，脉浮紧。',
          source: '伤寒论', heading: '太阳病');
      await insert('太阳之为病，脉浮，头项强痛而恶寒。',
          source: '伤寒论', heading: '第1条');

      final res = await Searcher.searchByQuery(db, '我感冒了怕冷没汗');

      expect(res, isNotEmpty);
      expect(res.first.text, contains('怕冷无汗'));
    });

    test('no-space CJK query without vocabulary falls back to 2-grams',
        () async {
      await insert('项背强几几，反汗出恶风者，桂枝加葛根汤主之。',
          source: '伤寒论', heading: '第14条');
      await insert('太阳之为病，脉浮。',
          source: '伤寒论', heading: '第1条');

      final res = await Searcher.searchByQuery(db, '项背强几几');

      expect(res, hasLength(1));
      expect(res.single.text, contains('项背强几几'));
    });

    test('empty query returns empty', () async {
      await insert('太阳之为病，脉浮。');

      expect(await Searcher.searchByQuery(db, '   '), isEmpty);
    });

    test('noise query with no real terms returns empty', () async {
      await insert('太阳之为病，脉浮，头项强痛而恶寒。');

      expect(await Searcher.searchByQuery(db, '不存在的词xyz'), isEmpty);
    });
  });

  group('QueryTerms.extract', () {
    test('vocabulary keywords to andTerms with synonym canonicalize', () {
      final terms = QueryTerms.extract('我感冒了怕冷没汗');

      expect(terms.andTerms, contains('感冒'));
      expect(terms.andTerms, contains('怕冷'));
      expect(terms.andTerms, contains('无汗'));
      expect(terms.andTerms, isNot(contains('没汗')));
      expect(terms.orTerms, isNotEmpty);
    });

    test('short CJK runs produce no orTerms', () {
      final terms = QueryTerms.extract('感冒 发热');

      expect(terms.andTerms, containsAll(['感冒', '发热']));
      expect(terms.orTerms, isEmpty);
    });

    test('deduplicates andTerms and orTerms', () {
      final terms = QueryTerms.extract('桂枝 桂枝 没汗 没汗');

      expect(
          terms.andTerms.where((t) => t == '桂枝').length, 1);
      expect(
          terms.andTerms.where((t) => t == '无汗').length, 1);
      expect(terms.orTerms.toSet().length, terms.orTerms.length);
    });

    test('whitespace separated mixed query', () {
      final terms = QueryTerms.extract('  感冒   发热 ');

      expect(terms.andTerms, containsAll(['感冒', '发热']));
      expect(terms.orTerms, isEmpty);
    });
  });
}
