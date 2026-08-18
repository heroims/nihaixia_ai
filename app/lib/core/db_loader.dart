import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nihaixia_app/core/database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DbLoader {
  /// 从 assets 拷贝 kb.sqlite3 到应用支持目录并打开。
  ///
  /// 本地副本缺失或大小与 assets 不一致时（如应用升级带了新库、上次写入
  /// 中途崩溃留下截断文件），重新从 assets 覆盖写入。
  ///
  /// [overrideDir] 仅供测试注入临时目录：flutter test 环境没有
  /// path_provider 插件，直接调用 getApplicationSupportDirectory 会抛
  /// MissingPluginException。提供 overrideDir 时跳过插件调用。
  static Future<AppDatabase> loadFromAssets({Directory? overrideDir}) async {
    final dir = overrideDir ?? await getApplicationSupportDirectory();
    final target = p.join(dir.path, 'kb.sqlite3');
    final data = await rootBundle.load('assets/kb/kb.sqlite3');
    final f = File(target);
    if (!await f.exists() || await f.length() != data.lengthInBytes) {
      await f.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return AppDatabase(NativeDatabase(File(target)));
  }
}