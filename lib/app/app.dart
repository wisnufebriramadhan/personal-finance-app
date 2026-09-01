import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/onboarding/pages/splash_page.dart';

class DompetkuApp extends StatelessWidget {
  const DompetkuApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Dompetku',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const SplashPage(),
  );
}
