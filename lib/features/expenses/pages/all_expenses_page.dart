import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../dashboard/viewmodels/finance_viewmodel.dart';
import '../widgets/expense_tile.dart';

class AllExpensesPage extends StatelessWidget {
  const AllExpensesPage({super.key, required this.finance});
  final FinanceViewModel finance;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: finance,
    builder: (context, child) => Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengeluaran ${DateFormat('MMM yyyy', 'id_ID').format(finance.selectedMonth)}',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: finance.periodItems
            .map(
              (expense) => ExpenseTile(
                expense: expense,
                onDelete: () => finance.deleteExpense(expense.id),
              ),
            )
            .toList(),
      ),
    ),
  );
}
