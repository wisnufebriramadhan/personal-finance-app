import 'package:flutter/material.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/viewmodels/finance_viewmodel.dart';
import '../widgets/insight_widgets.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key, required this.finance});
  final FinanceViewModel finance;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final expense in finance.items) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    final categories = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Analisis bulan ini',
            style: TextStyle(
              fontSize: 25,
              color: ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lihat pola pengeluaranmu secara ringkas.',
            style: TextStyle(color: Color(0xFF777B90)),
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                MetricCard(
                  label: 'Total keluar',
                  value: rupiah.format(finance.spent),
                  color: const Color(0xFFFFEEE9),
                ),
                const SizedBox(width: 12),
                MetricCard(
                  label: 'Transaksi',
                  value: '${finance.items.length}',
                  color: const Color(0xFFE8F8F1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Menurut kategori',
            style: TextStyle(
              fontSize: 18,
              color: ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            const EmptyInsightState()
          else
            ...categories.map(
              (category) =>
                  _CategoryCard(category: category, totalSpent: finance.spent),
            ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.totalSpent});
  final MapEntry<String, double> category;
  final double totalSpent;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              category.key,
              style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
            ),
            const Spacer(),
            Text(
              rupiah.format(category.value),
              style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: totalSpent == 0 ? 0 : category.value / totalSpent,
          minHeight: 7,
          borderRadius: BorderRadius.circular(9),
          backgroundColor: const Color(0xFFF0F1F6),
          valueColor: const AlwaysStoppedAnimation(mint),
        ),
      ],
    ),
  );
}
