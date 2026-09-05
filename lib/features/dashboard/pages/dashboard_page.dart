import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../expenses/pages/all_expenses_page.dart';
import '../../expenses/widgets/expense_tile.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../widgets/balance_overview.dart';
import '../widgets/budget_card.dart';
import '../widgets/empty_expense_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.finance,
    required this.onAddExpense,
  });
  final FinanceViewModel finance;
  final VoidCallback onAddExpense;
  @override
  Widget build(BuildContext context) {
    final rawMonth = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(finance.selectedMonth);
    final month = rawMonth[0].toUpperCase() + rawMonth.substring(1);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: navy,
                child: Text(
                  'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat datang,',
                    style: TextStyle(color: Color(0xFF777B90), fontSize: 12),
                  ),
                  Text(
                    finance.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.notifications_none_rounded),
            ],
          ),
          const SizedBox(height: 27),
          Row(
            children: [
              IconButton(
                tooltip: 'Bulan sebelumnya',
                onPressed: () => finance.selectMonth(
                  DateTime(
                    finance.selectedMonth.year,
                    finance.selectedMonth.month - 1,
                  ),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  month,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF73778B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Bulan berikutnya',
                onPressed: () => finance.selectMonth(
                  DateTime(
                    finance.selectedMonth.year,
                    finance.selectedMonth.month + 1,
                  ),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BudgetCard(finance: finance),
          const SizedBox(height: 16),
          BalanceOverview(finance: finance),
          const SizedBox(height: 25),
          Row(
            children: [
              const Text(
                'Pengeluaran terbaru',
                style: TextStyle(
                  fontSize: 18,
                  color: ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllExpensesPage(finance: finance),
                  ),
                ),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (finance.periodItems.isEmpty)
            EmptyExpenseState(onAddExpense: onAddExpense)
          else
            ...finance.periodItems
                .take(4)
                .map(
                  (expense) => ExpenseTile(
                    expense: expense,
                    onDelete: () => finance.deleteExpense(expense.id),
                  ),
                ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F8F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF168260),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    finance.budgetProgress > .8
                        ? 'Budget sudah mendekati batas. Prioritaskan pengeluaran yang penting, ya.'
                        : 'Kebiasaan kecil yang konsisten adalah kunci kondisi finansial yang lebih sehat.',
                    style: const TextStyle(
                      color: Color(0xFF276250),
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
