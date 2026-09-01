import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

InputDecoration appInput(String hint, IconData icon, {String? prefix}) =>
    InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixIcon: Icon(icon, color: const Color(0xFF777B90)),
      filled: true,
      fillColor: appBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );

ButtonStyle primaryButtonStyle() => FilledButton.styleFrom(
  backgroundColor: navy,
  minimumSize: const Size.fromHeight(56),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  textStyle: const TextStyle(fontWeight: FontWeight.w700),
);

void showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
