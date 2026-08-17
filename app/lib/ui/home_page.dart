import 'package:flutter/material.dart';
import 'qa_tab.dart';
import 'diagnosis_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('倪海厦中医问答')),
      body: IndexedStack(index: _index, children: const [QaTab(), DiagnosisTab()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: '自由问答'),
          NavigationDestination(icon: Icon(Icons.healing), label: '引导式诊断'),
        ],
      ),
    );
  }
}