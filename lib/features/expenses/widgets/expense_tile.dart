import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../models/expense.dart';

const _icons = {
  'food': Icons.restaurant_rounded,
  'transport': Icons.directions_car_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'bills': Icons.receipt_long_rounded,
  'health': Icons.favorite_rounded,
  'other': Icons.more_horiz_rounded,
};
String accountName(String source) => source == 'cash'
    ? 'Cash'
    : source == 'ewallet'
    ? 'E-Wallet'
    : 'Bank';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, required this.onDelete});
  final Expense expense;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(expense.id),
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) async =>
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Hapus transaksi?'),
            content: Text(
              '"${expense.name}" akan dihapus dan saldo ${accountName(expense.source)} akan dikembalikan sebesar ${rupiah.format(expense.amount)}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD94B3D),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false,
    onDismissed: (_) => onDelete(),
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAE7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.delete_outline, color: Color(0xFFD94B3D)),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_icons[expense.kind], color: navy, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${expense.category} • ${accountName(expense.source)} • ${DateFormat('d MMM', 'id_ID').format(expense.date)}',
                  style: const TextStyle(
                    color: Color(0xFF8B8FA2),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-${rupiah.format(expense.amount)}',
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}
