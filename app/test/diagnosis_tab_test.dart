import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/retrieval/qa_service.dart';
import 'package:nihaixia_app/rules/diagnosis_service.dart';
import 'package:nihaixia_app/ui/diagnosis_tab.dart';

DiagnosisService _fakeService() => DiagnosisService(
      answerOverride: (query, {retrievalQuery}) async => const QaResult(
        hasAnswer: true,
        answer: '根据知识库证据，建议继续补充脉象与时间线。',
        channel: 'retrieval',
      ),
    );

Widget _app() => MaterialApp(
      home: Scaffold(body: DiagnosisTab(diagnosisService: _fakeService())),
    );

void main() {
  testWidgets('提交前整合四步症状并展示检索结果', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('怕冷'));
    await tester.pump();
    await tester.tap(find.text('没汗'));
    await tester.pump();
    await tester.tap(find.text('身体酸痛'));
    await tester.pump();
    await tester.tap(find.text('口渴'));
    await tester.tap(find.text('整合症状并开始分析'));
    await tester.pumpAndSettle();

    expect(find.text('知识库检索'), findsOneWidget);
    expect(find.textContaining('根据知识库证据'), findsOneWidget);
    expect(find.text('修改症状'), findsOneWidget);
  });

  testWidgets('最后一问支持同时选择口渴和发热，且无症状不能提交', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('不确定/跳过'));
    await tester.pump();
    await tester.tap(find.text('不确定/跳过'));
    await tester.pump();
    await tester.tap(find.text('都没有/跳过'));
    await tester.pump();

    expect(find.text('整合症状并开始分析'), findsOneWidget);
    expect(find.text('至少选择一项症状后才能开始分析。'), findsOneWidget);
    await tester.tap(find.text('口渴'));
    await tester.tap(find.text('发热'));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });

  testWidgets('结果页可返回编辑或重新开始，选项不会继续触发请求', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('怕冷'));
    await tester.pump();
    await tester.tap(find.text('没汗'));
    await tester.pump();
    await tester.tap(find.text('头项强痛'));
    await tester.pump();
    await tester.tap(find.text('整合症状并开始分析'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('修改症状'));
    await tester.pump();
    expect(find.text('4/4 还有口渴或发热吗？'), findsOneWidget);
    await tester.tap(find.text('重新开始'));
    await tester.pump();
    expect(find.text('1/4 您怕冷、怕风，还是怕热？'), findsOneWidget);
    expect(find.text('重新开始'), findsNothing);
  });
}
