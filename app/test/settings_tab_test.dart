// app/test/settings_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/ui/settings_tab.dart';
import 'package:nihaixia_app/ui/widgets/warning_card.dart';

void main() {
  group('validateCloudUrl', () {
    test('null or empty 视为跳过（返回 null）', () {
      expect(validateCloudUrl(null), isNull);
      expect(validateCloudUrl(''), isNull);
    });

    test('纯空白视为跳过（返回 null）', () {
      expect(validateCloudUrl('   '), isNull);
    });

    test('合法 http/https URL 返回 null', () {
      expect(validateCloudUrl('https://api.example.com/v1'), isNull);
    });

    test('非法 scheme 返回错误', () {
      expect(validateCloudUrl('ftp://x'), isNotNull);
    });

    test('scheme 无 authority 返回错误（http://）', () {
      expect(validateCloudUrl('http://'), isNotNull);
    });

    test('scheme 无 host 返回错误（https:foo）', () {
      expect(validateCloudUrl('https:foo'), isNotNull);
    });

    test('URL 含空白返回错误（http://a b.com）', () {
      expect(validateCloudUrl('http://a b.com'), isNotNull);
    });
  });

  group('WarningCard', () {
    testWidgets('text 为 null 时不渲染卡片', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: WarningCard(text: null)),
      ));
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('普通答案不渲染卡片', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: WarningCard(text: '小柴胡汤什么时候用')),
      ));
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('答案含「胸痛」渲染卡片', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: WarningCard(text: '出现胸痛，请立即就医')),
      ));
      expect(find.textContaining('立即就医'), findsOneWidget);
    });

    // 注意：关键词按 substring 匹配，'不易昏迷' 仍含 '昏迷' 故会触发。
    // 这是当前刻意接受的「触发即报警」行为：宁可误报也不漏报急危重症。
    testWidgets('「不易昏迷」否定式表述仍渲染卡片', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: WarningCard(text: '患者不易昏迷，神志清楚')),
      ));
      expect(find.textContaining('立即就医'), findsOneWidget);
    });
  });
}