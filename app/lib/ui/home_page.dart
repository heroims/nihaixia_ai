import 'package:flutter/material.dart';
import 'package:nihaixia_app/core/database.dart';
import 'qa_tab.dart';
import 'diagnosis_tab.dart';
import 'settings_tab.dart';

class HomePage extends StatefulWidget {
  final AppDatabase? database;
  const HomePage({super.key, this.database});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('倪海厦中医问答')),
      body: IndexedStack(index: _index, children: [
        QaTab(db: widget.database),
        const DiagnosisTab(),
        const SettingsTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: '自由问答'),
          NavigationDestination(icon: Icon(Icons.healing), label: '引导式诊断'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}