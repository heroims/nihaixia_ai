import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';

void main() {
  test('方剂查询走结构化表', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.herbs).insert(HerbsCompanion.insert(
          name: '甘草',
          taste: const Value('甘平'),
          indications: const Value('益气补中，调和诸药'),
        ));
    await db.into(db.herbs).insert(HerbsCompanion.insert(
          name: '大枣',
          taste: const Value('甘温'),
          indications: const Value('补中益气，养血安神'),
        ));

    final svc = QaService(db);
    final r = await svc.answer('甘草有什么作用');

    expect(r.hasAnswer, true);
    expect(r.sources, isNotEmpty);
    expect(r.answer, contains('甘草'));
    expect(r.sources.first.source, '神农本草经');
    await db.close();
  });

  test('开放问题走子串检索兜底', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final svc = QaService(db);
    final r = await svc.answer('什么是法于阴阳');

    expect(r.hasAnswer, true);
    expect(r.sources, isNotEmpty);
    expect(r.sources.first.source, '黄帝内经');
    await db.close();
  });

  test('未知查询返回空', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final svc = QaService(db);
    final r = await svc.answer('asdfzxcvqwerty');

    expect(r.hasAnswer, false);
    expect(r.answer, '资料中未找到相关内容。');
    await db.close();
  });
}