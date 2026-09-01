import 'package:flutter/material.dart';

const navy = Color(0xFF121A43);
const mint = Color(0xFF72E3BA);
const ink = Color(0xFF1E2340);
const appBackground = Color(0xFFF7F8FC);

abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: appBackground,
    colorScheme: ColorScheme.fromSeed(seedColor: navy),
    appBarTheme: const AppBarTheme(backgroundColor: appBackground),
  );
}
