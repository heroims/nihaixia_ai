import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/app.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const NihaixiaApp());
    expect(find.text('占位'), findsOneWidget);
  });
}