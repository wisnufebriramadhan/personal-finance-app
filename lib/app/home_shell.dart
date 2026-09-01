import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/dashboard/viewmodels/finance_viewmodel.dart';
import '../features/dashboard/widgets/floating_bottom_menu.dart';
import '../features/expenses/widgets/add_expense_sheet.dart';
import '../features/insights/pages/insights_page.dart';
import '../features/settings/pages/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.finance});
  final FinanceViewModel finance;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  DateTime? _lastBackPressed;

  void _showAddExpense() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => AddExpenseSheet(finance: widget.finance),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.finance,
    builder: (context, child) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        final now = DateTime.now();
        if (_lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan kembali sekali lagi untuk keluar.'),
            ),
          );
        }
      },
      child: Scaffold(
        extendBody: true,
        body: switch (_index) {
          0 => DashboardPage(
            finance: widget.finance,
            onAddExpense: _showAddExpense,
          ),
          1 => InsightsPage(finance: widget.finance),
          _ => SettingsPage(finance: widget.finance),
        },
        floatingActionButton: _index == 0
            ? FloatingActionButton.extended(
                onPressed: _showAddExpense,
                backgroundColor: navy,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Catat pengeluaran'),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: FloatingBottomMenu(
          selectedIndex: _index,
          onItemTapped: (value) => setState(() => _index = value),
        ),
      ),
    ),
  );
}
