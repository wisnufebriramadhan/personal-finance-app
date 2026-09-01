import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/home_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/viewmodels/finance_viewmodel.dart';
import 'setup_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_openNextPage());
  }

  Future<void> _openNextPage() async {
    final finance = FinanceViewModel();
    await finance.load();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => finance.isReady
            ? HomeShell(finance: finance)
            : SetupPage(finance: finance),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: navy,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/app_icon/dompetku_icon.png',
              width: 104,
              height: 104,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'dompetku',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kelola uangmu, lebih tenang.',
            style: TextStyle(color: Color(0xFFBEC8EE)),
          ),
        ],
      ),
    ),
  );
}
