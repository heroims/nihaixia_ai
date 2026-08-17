import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/llm/llm_service.dart';
import 'package:nihaixia_app/llm/rag_synthesizer.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';

/// 可控 fake：isAvailable 恒真，generate 返回预设文本（'' 模拟空输出降级）。
class _FakeLlmService extends LlmService {
  final String output;
  _FakeLlmService(this.output) : super(modelPath: '/nonexistent.gguf');

  @override
  bool get isAvailable => true;

  @override
  Future<String?> generate(String prompt) async => output;
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
}
