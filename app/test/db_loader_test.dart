import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaixia_app/core/db_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('assets 库可被打开', () async {
    // flutter test 环境无 path_provider 插件，注入临时目录跳过插件调用。
    final dir = await Directory.systemTemp.createTemp('kb_loader_test');
    addTearDown(() => dir.delete(recursive: true));

    final db = await DbLoader.loadFromAssets(overrideDir: dir);
    expect(db, isNotNull);
    final n = await db.customSelect('SELECT COUNT(*) c FROM herbs').getSingle();
    expect(n.read<int>('c') > 0, true);
    await db.close();

    // 库文件已落在目标目录。
    final target = File('${dir.path}/kb.sqlite3');
    expect(target.existsSync(), true);
  });

  test('assets 中 kb.sqlite3 可被 rootBundle 加载', () async {
    final data = await rootBundle.load('assets/kb/kb.sqlite3');
    expect(data.lengthInBytes, greaterThan(0));
  });

  test('再次加载复用已有文件', () async {
    final dir = await Directory.systemTemp.createTemp('kb_loader_test');
    addTearDown(() => dir.delete(recursive: true));

    final db1 = await DbLoader.loadFromAssets(overrideDir: dir);
    await db1.close();
    final target = File('${dir.path}/kb.sqlite3');
    expect(target.existsSync(), true);

    final db2 = await DbLoader.loadFromAssets(overrideDir: dir);
    expect(db2, isNotNull);
    final n = await db2.customSelect('SELECT COUNT(*) c FROM herbs').getSingle();
    expect(n.read<int>('c') > 0, true);
    await db2.close();
  });
}