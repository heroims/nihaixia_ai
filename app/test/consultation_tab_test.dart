import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/cloud/cloud_config.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/llm/inference_session.dart';
import 'package:nihaixia_app/llm/rag_synthesizer.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'package:nihaixia_app/ui/qa_tab.dart';

class TestSession extends InferenceSession {
  final QaService qa;
  TestSession(this.qa) : super(null);
  @override
  QaService get service => qa;
}

void main() {
  testWidgets('聊天保留历史、显示确认按钮并支持新对话', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    var calls = 0;
    final session = TestSession(QaService(db,
        synthesizer: RagSynthesizer(
          null,
          cloudProvider: () async =>
              const CloudConfig(baseUrl: 'https://example.com', apiKey: 'k'),
          chatOverride: (_, __) async => calls++ == 0
              ? '{"action":"ask","text":"持续多久？"}'
              : '{"action":"confirm","text":"怕冷两天，请核对。"}',
        )));
    await tester
        .pumpWidget(MaterialApp(home: Scaffold(body: QaTab(session: session))));
    await tester.enterText(find.byType(TextField), '我怕冷');
    await tester.tap(find.text('问'));
    await tester.pumpAndSettle();
    expect(find.text('持续多久？'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '两天');
    await tester.tap(find.text('问'));
    await tester.pumpAndSettle();
    expect(find.text('我怕冷'), findsOneWidget);
    expect(find.text('信息无误，形成参考结果'), findsOneWidget);
    await tester.tap(find.text('新对话'));
    await tester.pumpAndSettle();
    expect(find.text('我怕冷'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await session.disposeAsync();
    await db.close();
  });
}
