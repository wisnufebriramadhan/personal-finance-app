import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EmptyExpenseState extends StatelessWidget {
  const EmptyExpenseState({super.key, required this.onAddExpense});
  final VoidCallback onAddExpense;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          color: Color(0xFF98A0BA),
          size: 35,
        ),
        const SizedBox(height: 10),
        const Text(
          'Belum ada pengeluaran',
          style: TextStyle(fontWeight: FontWeight.w800, color: ink),
        ),
        const SizedBox(height: 4),
        const Text(
          'Catat transaksi pertamamu untuk mulai memantau saldo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF777B90), fontSize: 12),
        ),
        TextButton(
          onPressed: onAddExpense,
          child: const Text('Catat sekarang'),
        ),
      ],
    ),
  );
}
