// hide matcher 同名 API：测试断言用 flutter_test 导出的 isNull/isNotNull。
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
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

  test('配置云端时优先云端，端侧不被调用', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final llm = _FakeLlmService('端侧回答');
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');
    var cloudCalls = 0;
    final synth = RagSynthesizer(llm, cloud: cfg, chatOverride: (c, msgs) async {
      cloudCalls++;
      return '<think>推理</think>云端回答';
    });
    final r = await QaService(db, synthesizer: synth).answer('什么是法于阴阳');

    expect(cloudCalls, 1);
    expect(llm.callCount, 0);
    expect(r.hasAnswer, true);
    expect(r.answer, '云端回答'); // think 块已剥离
    expect(r.channel, 'cloud');
    expect(r.channelNote, isNull);
    await db.close();
  });

  test('超长证据被截断到上下文预算内（回归：超长 prompt 原生崩溃）', () async {
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');
    String? captured;
    final synth = RagSynthesizer(null, cloud: cfg,
        chatOverride: (c, msgs) async {
      captured = msgs.first['content'];
      return '云端回答';
    });
    // 10 条 × 800 字 ≈ 8000+ 字符，远超 3000 字符预算。
    final evidences = List.generate(10, (i) => '证据$i：${'医' * 800}');
    final r = await synth.synthesize(question: '当归功效', evidences: evidences);

    expect(r?.channel, 'cloud');
    expect(captured, isNotNull);
    expect(captured!.length, lessThanOrEqualTo(3000));
    // 预算内应保留前几条高相关证据，而不是全部丢弃。
    expect(captured, contains('证据0'));
  });

  test('云端失败自动回退端侧', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final llm = _FakeLlmService('端侧回答');
    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');
    final synth = RagSynthesizer(llm, cloud: cfg, chatOverride: (c, msgs) async {
      throw Exception('网络错误');
    });
    final r = await QaService(db, synthesizer: synth).answer('什么是法于阴阳');

    expect(llm.callCount, 1);
    expect(r.hasAnswer, true);
    expect(r.answer, '端侧回答');
    expect(r.channel, 'local');
    expect(r.channelNote, isNotNull); // 携带云端失败原因，UI 可见
    expect(r.channelNote, contains('网络错误'));
    await db.close();
  });

  test('仅配置云端（无本地模型）也能合成', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    const cfg = CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');
    final synth = RagSynthesizer(null, cloud: cfg, chatOverride: (c, msgs) async {
      return '纯云端回答';
    });
    final r = await QaService(db, synthesizer: synth).answer('什么是法于阴阳');

    expect(r.hasAnswer, true);
    expect(r.answer, '纯云端回答');
    expect(r.channel, 'cloud');
    await db.close();
  });

  test('端侧直答（无云端）channel 标注为 local 且无 note', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final llm = _FakeLlmService('端侧回答');
    final r = await QaService(db, synthesizer: RagSynthesizer(llm)).answer('什么是法于阴阳');

    expect(r.channel, 'local');
    expect(r.channelNote, isNull);
    await db.close();
  });

  test('stripThink 处理闭合/未闭合/无思考块', () {
    expect(RagSynthesizer.stripThink('<think>abc</think>正文'), '正文');
    expect(RagSynthesizer.stripThink('<think>abc截断'), '');
    expect(RagSynthesizer.stripThink('普通回答'), '普通回答');
  });

  test('cloudProvider 每次提问实时读取配置（保存后无需重启）', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.rawChunks).insert(RawChunksCompanion.insert(
          source: const Value('黄帝内经'),
          heading: const Value('上古天真论'),
          content: '上古之人，其知道者，法于阴阳，和于术数。',
        ));

    final llm = _FakeLlmService('端侧回答');
    var providerCalls = 0;
    CloudConfig? current; // 初始未配置
    final synth = RagSynthesizer(llm, cloudProvider: () async {
      providerCalls++;
      return current;
    }, chatOverride: (c, msgs) async => '云端回答');

    // 第一次：无云端 → 走端侧
    final r1 = await QaService(db, synthesizer: synth).answer('什么是法于阴阳');
    expect(r1.answer, '端侧回答');

    // 用户在设置页保存云端配置后
    current = const CloudConfig(baseUrl: 'https://api.example.com/v1', apiKey: 'k');

    // 第二次：立即走云端，无需重建合成器
    final r2 = await QaService(db, synthesizer: synth).answer('什么是法于阴阳');
    expect(providerCalls, 2);
    expect(llm.callCount, 1); // 端侧只在第一次被调用
    expect(r2.answer, '云端回答');
    await db.close();
  });
}
