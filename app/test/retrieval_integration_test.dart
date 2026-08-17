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

  test('数据库异常返回检索失败而非崩溃', () async {
    final db = AppDatabase(NativeDatabase.memory());
    // 先写一条触发连接打开，否则「从未打开就 close」的 in-memory 连接查询会
    // 静默返回空而非抛错，无法走到 QaService 的异常兜底分支。
    await db.into(db.herbs).insert(HerbsCompanion.insert(name: '甘草'));
    final svc = QaService(db);
    await db.close();

    final r = await svc.answer('甘草有什么作用');

    expect(r.hasAnswer, false);
    expect(r.answer, '检索出现异常，请重试。');
  });

  test('柴胡别名查询返回结构化解药与来源', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.herbs).insert(HerbsCompanion.insert(
          name: '茈胡',
          taste: const Value('苦平'),
          indications: const Value('主心腹去肠胃中结气'),
        ));

    final svc = QaService(db);
    final r = await svc.answer('柴胡');

    expect(r.hasAnswer, true);
    expect(r.sources, isNotEmpty);
    expect(r.answer, contains('茈胡（柴胡）'));
    expect(r.sources.first.source, '神农本草经');
    await db.close();
  });
}