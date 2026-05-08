import 'package:flutter/material.dart';

import 'curves_tab.dart';
import 'diagnostics_tab.dart';
import 'fee_tab.dart';
import 'info_tab.dart';
import 'theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iCDS',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.orange,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppTheme.orange,
          secondary: AppTheme.orange,
        ),
      ),
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  static const _tabs = <Widget>[
    FeeTab(),
    CurvesTab(),
    InfoTab(),
    DiagnosticsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: AppTheme.orange,
        unselectedItemColor: const Color(0xFF808080),
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined), label: 'Fee'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Curves'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Info'),
          BottomNavigationBarItem(icon: Icon(Icons.science_outlined), label: 'Diag'),
        ],
      ),
    );
  }
}
