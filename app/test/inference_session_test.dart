import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nihaixia_app/core/database.dart';
import 'package:nihaixia_app/llm/inference_session.dart';
import 'package:nihaixia_app/llm/inference_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(
      {'inference_mode': InferenceMode.retrievalOnly.index});

  test('retrieval-only session exposes a stable shared QA service', () async {
    await InferenceSettings.instance.setMode(InferenceMode.retrievalOnly);
    final db = AppDatabase(NativeDatabase.memory());
    final session = InferenceSession(db);
    final initial = session.service;

    expect(initial, isNotNull);
    await session.initialize();

    expect(session.service, same(initial));
    await session.disposeAsync();
    await db.close();
  });
}
