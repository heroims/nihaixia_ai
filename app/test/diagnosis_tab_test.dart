import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/ui/diagnosis_tab.dart';

void main() {
  testWidgets('问卷三问后给出辨证', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DiagnosisTab())));
    // 问题1: 寒热
    await tester.tap(find.text('怕冷'));
    await tester.pump();
    // 问题2: 汗出
    await tester.tap(find.text('没汗'));
    await tester.pump();
    // 问题3: 头项/身体痛
    await tester.tap(find.text('头项强痛'));
    await tester.pump();
    // 问题4: 完成辨证
    await tester.tap(find.text('都没有/完成辨证'));
    await tester.pump();
    expect(find.textContaining('太阳病'), findsOneWidget);
  });

  testWidgets('全部跳过 → 信息不足，不显示空辨证', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DiagnosisTab())));
    await tester.tap(find.text('不确定/跳过'));
    await tester.pump();
    await tester.tap(find.text('不确定/跳过'));
    await tester.pump();
    await tester.tap(find.text('都没有/跳过'));
    await tester.pump();
    await tester.tap(find.text('都没有/完成辨证'));
    await tester.pump();
    expect(find.text('信息不足，无法辨证'), findsOneWidget);
    expect(find.textContaining('辨证：'), findsNothing);
  });

  testWidgets('完成辨证后可重新开始问卷', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DiagnosisTab())));
    await tester.tap(find.text('怕冷'));
    await tester.pump();
    await tester.tap(find.text('没汗'));
    await tester.pump();
    await tester.tap(find.text('头项强痛'));
    await tester.pump();
    await tester.tap(find.text('都没有/完成辨证'));
    await tester.pump();
    expect(find.textContaining('太阳病'), findsOneWidget);
    await tester.tap(find.text('重新开始'));
    await tester.pump();
    expect(find.text('1/4 您怕冷、怕风，还是怕热？'), findsOneWidget);
    expect(find.text('怕冷'), findsOneWidget);
    expect(find.textContaining('太阳病'), findsNothing);
    expect(find.text('重新开始'), findsNothing);
  });
}