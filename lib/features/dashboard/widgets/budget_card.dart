import 'package:flutter/material.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/finance_viewmodel.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.finance});
  final FinanceViewModel finance;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(25),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33121A43),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              finance.budget > 0 ? 'Sisa budget' : 'Budget bulanan',
              style: const TextStyle(
                color: Color(0xFFBFC7EE),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              finance.budget > 0
                  ? '${(finance.budgetProgress * 100).round()}% terpakai'
                  : 'Opsional',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          finance.budget > 0
              ? rupiah.format(finance.remainingBudget)
              : 'Belum diatur',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            value: finance.budgetProgress,
            minHeight: 9,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(
              finance.budgetProgress > .8 ? const Color(0xFFFFB0A1) : mint,
            ),
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Text(
              finance.budget > 0
                  ? 'Terpakai ${rupiah.format(finance.spent)}'
                  : 'Tetap bisa mencatat',
              style: const TextStyle(color: Color(0xFFCBD1EF), fontSize: 12),
            ),
            const Spacer(),
            Text(
              finance.budget > 0
                  ? 'dari ${rupiah.format(finance.budget)}'
                  : 'Atur nanti',
              style: const TextStyle(color: Color(0xFFCBD1EF), fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}
