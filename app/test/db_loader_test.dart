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
    // 用同尺寸的哨兵改动本地库：改短一行内容，文件大小不变但内容已变。
    await db1.customUpdate(
      "UPDATE herbs SET name = 'sentinel' WHERE id = "
      '(SELECT id FROM herbs ORDER BY id LIMIT 1)',
    );
    await db1.close();
    final target = File('${dir.path}/kb.sqlite3');
    expect(target.existsSync(), true);
    final before = await target.readAsBytes();

    final db2 = await DbLoader.loadFromAssets(overrideDir: dir);
    expect(db2, isNotNull);
    // 内容仍为哨兵 → 文件未被重写，验证了同尺寸复用。
    final s = await db2.customSelect(
      "SELECT COUNT(*) c FROM herbs WHERE name = 'sentinel'",
    ).getSingle();
    expect(s.read<int>('c'), 1);
    final n = await db2.customSelect('SELECT COUNT(*) c FROM herbs').getSingle();
    expect(n.read<int>('c') > 0, true);
    await db2.close();

    expect(await target.readAsBytes(), equals(before));
  });

  test('本地文件被截断时重新从 assets 覆盖', () async {
    final dir = await Directory.systemTemp.createTemp('kb_loader_test');
    addTearDown(() => dir.delete(recursive: true));

    final db1 = await DbLoader.loadFromAssets(overrideDir: dir);
    await db1.close();
    final target = File('${dir.path}/kb.sqlite3');
    expect(target.existsSync(), true);

    // 截断本地文件（长度与 assets 不一致），再次加载应自愈。
    final truncated = target.readAsBytesSync().sublist(0, 100);
    await target.writeAsBytes(truncated, flush: true);
    expect(target.lengthSync(), 100);

    final db2 = await DbLoader.loadFromAssets(overrideDir: dir);
    expect(db2, isNotNull);
    final data = await rootBundle.load('assets/kb/kb.sqlite3');
    expect(target.lengthSync(), data.lengthInBytes);
    final n = await db2.customSelect('SELECT COUNT(*) c FROM herbs').getSingle();
    expect(n.read<int>('c') > 0, true);
    await db2.close();
  });
}