import 'package:flutter/material.dart';
import 'main_navigation_shell.dart';
import 'theme.dart';

class OneGateApp extends StatelessWidget {
  const OneGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneGate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}
