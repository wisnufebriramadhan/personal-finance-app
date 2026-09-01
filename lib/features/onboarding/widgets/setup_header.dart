import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SetupHeader extends StatelessWidget {
  const SetupHeader({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3FAF1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          color: navy,
          size: 32,
        ),
      ),
      const SizedBox(height: 28),
      const Text(
        'Atur saldo &\nrencana belanjamu.',
        style: TextStyle(
          fontSize: 32,
          height: 1.12,
          color: ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Saldo akun mencerminkan uang yang tersedia. Budget adalah batas belanja yang kamu rencanakan—keduanya tidak harus sama.',
        style: TextStyle(color: Color(0xFF6D7187), height: 1.5),
      ),
    ],
  );
}
