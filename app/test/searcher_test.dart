import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/core/models.dart';
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

  test('substring search returns matching chunk', () async {
    await insert('太阳之为病，脉浮，头项强痛而恶寒。',
        source: '伤寒论', heading: '第1条');
    await insert('夫治未病者，见肝之病，知肝传脾。',
        source: '金匮', heading: '卒病');

    final res = await Searcher.searchRawChunks(db, '恶寒');

    expect(res, isNotEmpty);
    expect(res.first.text, contains('恶寒'));
    expect(res.first.source, '伤寒论');
    expect(res.first.heading, '第1条');
  });

  test('multiword AND requires all words', () async {
    await insert('太阳之为病，脉浮，头项强痛而恶寒。');
    await insert('太阳之为病，脉浮。');

    final res = await Searcher.searchRawChunks(db, '脉浮 恶寒');

    expect(res, hasLength(1));
    expect(res.single.text, contains('恶寒'));
  });

  test('no match returns empty', () async {
    await insert('太阳之为病，脉浮，头项强痛而恶寒。');

    expect(await Searcher.searchRawChunks(db, '不存在的词xyz'), isEmpty);
  });

  test('empty query returns empty', () async {
    await insert('太阳之为病，脉浮。');

    expect(await Searcher.searchRawChunks(db, '   '), isEmpty);
  });

  test('results ranked by occurrence count', () async {
    await insert('桂枝，桂枝，桂枝，善治感冒。');
    await insert('桂枝汤主治太阳中风。');

    final res = await Searcher.searchRawChunks(db, '桂枝');

    expect(res, hasLength(2));
    expect(res.first.text, contains('桂枝，桂枝，桂枝'));
  });

  test('returns SearchHit model', () async {
    await insert('太阳之为病，脉浮，头项强痛而恶寒。',
        source: '伤寒论', heading: '第1条');

    final res = await Searcher.searchRawChunks(db, '恶寒');

    expect(res.first, isA<SearchHit>());
    expect(res.first.source, '伤寒论');
    expect(res.first.heading, '第1条');
    expect(res.first.text, isNotEmpty);
  });
}