# 引导式诊断 RAG 重设计 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将引导式诊断接入共享的检索/RAG 推理链路，并完善问卷状态、来源展示、降级和 README。

**Architecture:** `HomePage` 持有一个共享 `InferenceSession`，负责按推理模式创建单一 `QaService`/端侧模型；`QaTab` 和 `DiagnosisTab` 通过会话消费同一服务。`DiagnosisService` 将 `SymptomInput` 转成检索词和完整诊断 prompt，调用 `QaService.answer(query:, retrievalQuery:)`，最终由云端、端侧或知识库原文返回。

**Tech Stack:** Flutter/Dart, Drift SQLite, existing `LlmService`, `RagSynthesizer`, Flutter widget tests。

---

### Task 1: 扩展 QA 查询接口，分离模型问题与检索词

**Files:**
- Modify: `app/lib/retrieval/qa_service.dart`
- Test: `app/test/retrieval_integration_test.dart`

- [ ] **Step 1: 写失败测试**

  在 `retrieval_integration_test.dart` 增加一个内存数据库测试：插入含“怕冷、无汗、头项强痛”的 `raw_chunks`，调用：

  ```dart
  final result = await QaService(db).answer(
    '请根据症状判断六经方向：怕冷、无汗、头项强痛。',
    retrievalQuery: '怕冷 无汗 头项强痛',
  );
  expect(result.hasAnswer, isTrue);
  expect(result.sources.single.text, contains('头项强痛'));
  ```

  同时用 fake synthesizer/LLM 断言传入模型的 prompt 包含完整诊断句，而不是只包含短检索词。

- [ ] **Step 2: 运行测试确认失败**

  ```bash
  cd app && flutter test test/retrieval_integration_test.dart
  ```

  预期因为 `answer` 尚不接受 `retrievalQuery` 命名参数而失败。

- [ ] **Step 3: 实现最小接口改动**

  将签名改为：

  ```dart
  Future<QaResult> answer(String query, {String? retrievalQuery}) async {
    final searchQuery = retrievalQuery?.trim().isNotEmpty == true
        ? retrievalQuery!.trim()
        : query;
    final intent = IntentRouter.classify(searchQuery);
    // 结构化查询、Searcher.searchByQuery 全部使用 searchQuery；
    // _synthesize(query, hits) 继续使用完整 query。
  }
  ```

  结构化 `_answerStructured` 也接收 `searchQuery`，保证诊断查询不会误走药材/方剂结构化分支；自由问答未传该参数时行为保持不变。

- [ ] **Step 4: 运行测试确认通过**

  ```bash
  cd app && flutter test test/retrieval_integration_test.dart
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add app/lib/retrieval/qa_service.dart app/test/retrieval_integration_test.dart
  git commit -m "feat: separate diagnosis prompt and retrieval query"
  ```

### Task 2: 共享 InferenceSession

**Files:**
- Create: `app/lib/llm/inference_session.dart`
- Modify: `app/lib/ui/home_page.dart`
- Modify: `app/lib/ui/qa_tab.dart`
- Modify: `app/lib/ui/settings_tab.dart` only if a listener hook is needed
- Test: `app/test/inference_session_test.dart`

- [ ] **Step 1: 写失败测试**

  测试 session 在 `InferenceMode.retrievalOnly` 下立即提供 `QaService`，模式切换通知只产生一个服务实例；测试注入的 `resolveLocal`/`loadCloud` 回调不加载真实 GGUF。

- [ ] **Step 2: 运行测试确认失败**

  ```bash
  cd app && flutter test test/inference_session_test.dart
  ```

  预期因为 `InferenceSession` 尚不存在而失败。

- [ ] **Step 3: 实现 session**

  `InferenceSession` 继承 `ChangeNotifier`，暴露：

  ```dart
  class InferenceSession extends ChangeNotifier {
    final AppDatabase? db;
    QaService? get service;
    Future<void> initialize();
    Future<void> refresh();
    @override void dispose();
  }
  ```

  把 `QaTab` 当前的模式接线逻辑迁入 `initialize/refresh`：持有一个 `LlmService?`，用 generation token 取消过期异步流程，模式为纯检索时不解析模型；云端优先通过 `CloudConfigStore.load` provider 实时读取；没有任何通道时创建 `QaService(db)`。所有异步 dispose 串行执行，避免 llama 全局日志回调竞态。

- [ ] **Step 4: 接入 HomePage 与 QaTab**

  `HomePage` 在 `initState` 创建 `InferenceSession(database)`，在 `dispose` 释放；通过 `ListenableBuilder`/session getter 将同一个 session 传给 `QaTab(session:)` 和 `DiagnosisTab(session:)`。`QaTab` 删除 `_llm`、`_wiring`、`_initLlm` 及模式监听，只监听 session 更新并读取 `session.service`；保留请求令牌和 UI 渲染逻辑。

- [ ] **Step 5: 运行共享会话测试与现有 widget 测试**

  ```bash
  cd app && flutter test test/inference_session_test.dart test/widget_test.dart
  ```

- [ ] **Step 6: Commit**

  ```bash
  git add app/lib/llm/inference_session.dart app/lib/ui/home_page.dart app/lib/ui/qa_tab.dart app/test/inference_session_test.dart
  git commit -m "refactor: share inference session across tabs"
  ```

### Task 3: DiagnosisService 与规则基线

**Files:**
- Create: `app/lib/rules/diagnosis_service.dart`
- Modify: `app/lib/rules/diagnostic_engine.dart`
- Test: `app/test/diagnosis_service_test.dart`
- Modify: `app/test/diagnostic_engine_test.dart`

- [ ] **Step 1: 写失败测试**

  覆盖以下行为：

  ```dart
  final input = SymptomInput(
    cold: ColdState.aversionToCold,
    sweat: SweatState.noSweat,
    bodyAche: true,
    thirst: true,
    fever: true,
  );
  final result = await DiagnosisService(QaService(db)).diagnose(input);
  expect(result.query, contains('口渴'));
  expect(result.retrievalQuery, contains('无汗'));
  expect(result.qa.channel, 'retrieval');
  ```

  用 fake `QaService` 不易注入，因此服务构造函数接收 `Future<QaResult> Function(String, String)` 的 `answer` 回调；测试断言完整 prompt、检索词、规则线索和返回元数据。

- [ ] **Step 2: 运行测试确认失败**

  ```bash
  cd app && flutter test test/diagnosis_service_test.dart
  ```

- [ ] **Step 3: 修复规则并实现服务**

  将太阳伤寒条件改为 `s.painNeck || s.bodyAche`；太阳中风仍要求 `painNeck`。新增不可变 `DiagnosisResponse`：`question`、`retrievalQuery`、`QaResult qa`、`DiagnosisResult ruleHint`。

  `DiagnosisService.buildQuestion` 固定输出：症状摘要、规则线索（若有）、“只基于资料回答/资料不足要明说/注明出处/仅供学习参考”的约束。`buildRetrievalQuery` 只加入已选择的正向术语，顺序固定为寒热、汗出、颈项痛、身体酸痛、口渴、发热；通过 `QaService.answer(question, retrievalQuery: retrievalQuery)` 执行。

- [ ] **Step 4: 运行服务与规则测试确认通过**

  ```bash
  cd app && flutter test test/diagnosis_service_test.dart test/diagnostic_engine_test.dart
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add app/lib/rules app/test/diagnosis_service_test.dart app/test/diagnostic_engine_test.dart
  git commit -m "feat: add retrieval-backed diagnosis service"
  ```

### Task 4: 重做 DiagnosisTab 状态机与结果展示

**Files:**
- Modify: `app/lib/ui/diagnosis_tab.dart`
- Modify: `app/test/diagnosis_tab_test.dart`
- Modify: `app/test/widget_test.dart` if constructor changes require smoke updates

- [ ] **Step 1: 写失败 widget 测试**

  增加测试：

  1. 第四步可同时点“口渴”和“发热”，点“完成辨证”后只出现一次 loading/结果；
  2. “上一步”返回第三步且保留已选答案；修改后完成；
  3. 结果态不再渲染问题选项，展示 `云端模型`/`端侧模型`/`知识库原文` channel 和来源；
  4. 点击“重新编辑”回到问卷，点击“重新开始”清空答案。

- [ ] **Step 2: 运行测试确认失败**

  ```bash
  cd app && flutter test test/diagnosis_tab_test.dart
  ```

- [ ] **Step 3: 实现状态机**

  `DiagnosisTab` 接收 `InferenceSession? session`，维护 `DiagnosisStep {editing, submitting, result, error}`、`_q`、`_input`、`_response` 和 `_requestId`。前 3 步选项写入 immutable `SymptomInput` 后前进；第四步的口渴/发热使用 toggle，不自动提交；“完成辨证”在至少一个症状时进入 submitting，调用 `session.service` 的 `DiagnosisService`，无服务时进入 error。

  编辑态显示进度、问题、选项和“上一步”；提交态只显示 `CircularProgressIndicator`；结果态显示 `MarkdownBody`、来源列表、channel chip、规则线索（若存在）和“重新编辑/重新开始”；请求完成时只接受当前 `_requestId` 的结果。保留免责声明与急症 `WarningCard`。

- [ ] **Step 4: 运行 widget 测试确认通过**

  ```bash
  cd app && flutter test test/diagnosis_tab_test.dart test/widget_test.dart
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add app/lib/ui/diagnosis_tab.dart app/test/diagnosis_tab_test.dart app/test/widget_test.dart
  git commit -m "feat: rebuild guided diagnosis questionnaire flow"
  ```

### Task 5: README 与最终验证

**Files:**
- Modify: `README.md`
- Modify: `app/README.md`

- [ ] **Step 1: 更新文档**

  在根 README 的 AI 工程表和 Mermaid 数据流中加入 `DiagnosisTab → DiagnosisService → QaService(retrievalQuery + prompt) → RAG/fallback`；在面试演示章节加入“填症状、切换推理模式、展示 channel/source、断开模型看检索降级”。`app/README.md` 增加诊断状态、共享 session 和测试入口说明。

- [ ] **Step 2: 文档一致性检查**

  ```bash
  rg -n "DiagnosisService|InferenceSession|retrievalQuery|引导式诊断|身体酸痛|上一步|知识库原文" README.md app/README.md app/lib app/test
  git diff --check
  ```

- [ ] **Step 3: 运行完整验证**

  ```bash
  cd app
  flutter test
  flutter build apk --debug
  flutter build ios --no-codesign --simulator
  dart analyze
  ```

  预期测试与两个平台构建通过；`dart analyze` 若只报告现有第三方 unreachable switch、Flutter deprecation 和缺失本地 GGUF asset warning，需在交付中明确记录，不把 warning 冒充为新回归。

- [ ] **Step 4: 检查工作区与提交**

  ```bash
  git status --short
  git ls-files '*.gguf'
  git add README.md app/README.md
  git commit -m "docs: document guided diagnosis RAG flow"
  ```
