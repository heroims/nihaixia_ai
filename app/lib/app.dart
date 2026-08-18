import 'package:flutter/material.dart';
import 'core/database.dart';
import 'ui/home_page.dart';

class NihaixiaApp extends StatelessWidget {
  final AppDatabase? database;
  const NihaixiaApp({super.key, this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '倪海厦中医问答',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: HomePage(database: database),
    );
  }
}