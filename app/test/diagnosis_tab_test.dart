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
}