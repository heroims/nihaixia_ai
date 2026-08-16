import 'package:flutter/material.dart';
import 'ui/home_page.dart';

class NihaixiaApp extends StatelessWidget {
  const NihaixiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '倪海厦中医问答',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomePage(),
    );
  }
}