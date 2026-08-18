import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/llm/llm_service.dart';
import 'package:nihaixia_app/llm/rag_synthesizer.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';

/// 可控 fake：isAvailable 默认恒真（可配 false 模拟不可用），generate 行为可配
/// （预设输出 / 返回 null / 抛异常），并记录调用次数与最后一次 prompt 供断言。
class _FakeLlmService extends LlmService {
  final String? output;
  final bool throwOnGenerate;
  final bool available;
  int callCount = 0;
  String? lastPrompt;

  _FakeLlmService(this.output,
      {this.throwOnGenerate = false, this.available = true})
      : super(modelPath: '/nonexistent.gguf');

  @override
  bool get isAvailable => available;

  @override
  Future<String?> generate(String prompt) async {
    callCount++;
    lastPrompt = prompt;
    if (throwOnGenerate) throw StateError('模拟 LLM 推理异常');
    return output;
  }
}

void main() {
  test('LLM 不可用时 QA 返回检索原文摘要', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.herbs).insert(HerbsCompanion.insert(
          name: '麻黄',
          taste: const Value('辛微苦温'),
          indications: const Value('发汗解表，宣肺平喘'),
        ));

    final llm = LlmService(modelPath: '/nonexistent.gguf'); // not available
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    final r = await svc.answer('麻黄性味');

    expect(r.hasAnswer, true);
    expect(r.answer, contains('麻黄'));
    await db.close();
  });

  test('LLM 可用时 RAG 合成回答生效', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final llm = _FakeLlmService('这是RAG合成回答');
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    final r = await svc.answer('什么是法于阴阳');

    expect(r.hasAnswer, true);
    expect(r.answer, '这是RAG合成回答');
    expect(r.sources, isNotEmpty);
    expect(r.sources.first.source, '黄帝内经');
    await db.close();
  });

  test('LLM 返回空串时降级为检索原文', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final llm = _FakeLlmService('');
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    final r = await svc.answer('什么是法于阴阳');

    expect(r.hasAnswer, true);
    expect(r.answer, contains('法于阴阳'));
    await db.close();
  });

  test('LLM 返回纯空白时降级为检索原文', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final llm = _FakeLlmService('   ');
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    final r = await svc.answer('什么是法于阴阳');

    expect(r.hasAnswer, true);
    expect(r.answer, contains('法于阴阳'));
    await db.close();
  });

  test('LLM 可用但返回 null 时降级为检索原文', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final llm = _FakeLlmService(null);
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    final r = await svc.answer('什么是法于阴阳');

    expect(r.hasAnswer, true);
    expect(r.answer, contains('法于阴阳'));
    await db.close();
  });

  test('LLM 合成抛异常时降级为检索原文而非检索异常', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final llm = _FakeLlmService('x', throwOnGenerate: true);
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    final r = await svc.answer('什么是法于阴阳');

    expect(r.hasAnswer, true);
    expect(r.answer, contains('法于阴阳'));
    expect(r.answer, isNot(contains('检索出现异常')));
    await db.close();
  });

  test('结构化路径命中且合成器可用时返回合成答案', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.herbs).insert(HerbsCompanion.insert(
          name: '麻黄',
          taste: const Value('辛微苦温'),
          indications: const Value('发汗解表，宣肺平喘'),
        ));

    final llm = _FakeLlmService('这是结构化RAG合成回答');
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    final r = await svc.answer('麻黄性味');

    expect(r.hasAnswer, true);
    expect(r.answer, '这是结构化RAG合成回答');
    expect(llm.callCount, 1);
    expect(r.sources, isNotEmpty);
    expect(r.sources.first.source, '神农本草经');
    await db.close();
  });

  test('结构化路径命中但合成器不可用时降级为原文 dump', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.herbs).insert(HerbsCompanion.insert(
          name: '麻黄',
          taste: const Value('辛微苦温'),
          indications: const Value('发汗解表，宣肺平喘'),
        ));

    // available:false 镜像真实 LlmService('/nonexistent.gguf') 的不可用语义
    // （isAvailable=false → RagSynthesizer.enabled=false，合成器不被调用）。
    final llm = _FakeLlmService('x', available: false);
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    final r = await svc.answer('麻黄性味');

    expect(r.hasAnswer, true);
    expect(llm.callCount, 0);
    expect(r.answer, contains('麻黄'));
    await db.close();
  });

  test('结构化路径命中但合成器输出为空时降级为原文 dump', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.herbs).insert(HerbsCompanion.insert(
          name: '麻黄',
          taste: const Value('辛微苦温'),
          indications: const Value('发汗解表，宣肺平喘'),
        ));

    final llm = _FakeLlmService('');
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    final r = await svc.answer('麻黄性味');

    expect(r.hasAnswer, true);
    expect(llm.callCount, 1);
    expect(r.answer, contains('麻黄'));
    await db.close();
  });

  test('RAG 证据按 source·heading：text 格式传入合成器', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final llm = _FakeLlmService('合成回答');
    final svc = QaService(db, synthesizer: RagSynthesizer(llm));
    await svc.answer('什么是法于阴阳');

    expect(
      llm.lastPrompt,
      contains('黄帝内经·上古天真论：上古之人，其知道者，法于阴阳，和于术数。'),
    );
    await db.close();
  });
}
