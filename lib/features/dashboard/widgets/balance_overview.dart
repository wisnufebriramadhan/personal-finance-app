import 'package:flutter/material.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/finance_viewmodel.dart';

class BalanceOverview extends StatelessWidget {
  const BalanceOverview({super.key, required this.finance});
  final FinanceViewModel finance;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Saldo akun',
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              rupiah.format(finance.totalBalance),
              style: const TextStyle(color: navy, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _BalanceItem(
              'Cash',
              finance.cash,
              Icons.payments_rounded,
              const Color(0xFFFFF0D9),
            ),
            const SizedBox(width: 8),
            _BalanceItem(
              'E-Wallet',
              finance.ewallet,
              Icons.account_balance_wallet_rounded,
              const Color(0xFFE7F1FF),
            ),
            const SizedBox(width: 8),
            _BalanceItem(
              'Bank',
              finance.bank,
              Icons.account_balance_rounded,
              const Color(0xFFE8F8F1),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem(this.label, this.value, this.icon, this.color);
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: navy, size: 18),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF61667A)),
          ),
          const SizedBox(height: 2),
          Text(
            rupiah.format(value),
            style: const TextStyle(
              fontSize: 11,
              color: ink,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
