import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/app.dart';

void main() {
  testWidgets('app shows two tabs and disclaimer', (tester) async {
    await tester.pumpWidget(const NihaixiaApp());
    expect(find.text('自由问答'), findsOneWidget);
    expect(find.text('引导式诊断'), findsOneWidget);
    expect(find.textContaining('仅供学习参考'), findsWidgets);
  });
}