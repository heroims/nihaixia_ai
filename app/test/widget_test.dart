import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/app.dart';
import 'package:nihaixia_app/core/models.dart';
import 'package:nihaixia_app/ui/widgets/source_list.dart';
import 'package:nihaixia_app/ui/widgets/warning_card.dart';

void main() {
  testWidgets('app shows two tabs and disclaimer', (tester) async {
    await tester.pumpWidget(const NihaixiaApp());
    expect(find.text('自由问答'), findsOneWidget);
    expect(find.text('引导式诊断'), findsOneWidget);
    expect(find.textContaining('仅供学习参考'), findsWidgets);
  });

  testWidgets('SourceList renders source·heading per hit', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SourceList(sources: [
          SearchHit(source: '神农本草经', heading: '甘草', text: '甘平'),
          SearchHit(source: '伤寒论', heading: '第1条', text: '太阳之为病'),
        ]),
      ),
    ));
    expect(find.text('（来源）'), findsOneWidget);
    expect(find.text('· 神农本草经·甘草'), findsOneWidget);
    expect(find.text('· 伤寒论·第1条'), findsOneWidget);
  });

  testWidgets('SourceList with empty sources renders nothing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SourceList(sources: [])),
    ));
    expect(find.text('（来源）'), findsNothing);
  });

  testWidgets('settings tab accessible', (tester) async {
    await tester.pumpWidget(const NihaixiaApp());
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('emergency warning card renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: WarningCard(text: '出现胸痛，请立即就医')),
    ));
    expect(find.textContaining('立即就医'), findsOneWidget);
  });
}