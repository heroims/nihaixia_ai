import 'package:flutter/material.dart';
import 'app.dart';
import 'core/database.dart';
import 'core/db_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase? db;
  try {
    db = await DbLoader.loadFromAssets();
  } catch (e) {
    // 数据库不可用仍可启动（检索层会降级提示）。
    debugPrint('[main] assets db 加载失败，降级启动（无检索）：$e');
  }
  runApp(NihaixiaApp(database: db));
}