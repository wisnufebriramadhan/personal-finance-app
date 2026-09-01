import 'package:flutter/material.dart';

import '../../../app/home_shell.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_controls.dart';
import '../../dashboard/viewmodels/finance_viewmodel.dart';
import '../widgets/setup_header.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key, required this.finance});
  final FinanceViewModel finance;
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _name = TextEditingController(),
      _budget = TextEditingController(),
      _cash = TextEditingController(),
      _wallet = TextEditingController(),
      _bank = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    _cash.dispose();
    _wallet.dispose();
    _bank.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      showMessage(context, 'Masukkan nama kamu terlebih dahulu.');
      return;
    }
    await widget.finance.setup(
      name: _name.text,
      budgetValue: parseRupiah(_budget.text),
      cashValue: parseRupiah(_cash.text),
      ewalletValue: parseRupiah(_wallet.text),
      bankValue: parseRupiah(_bank.text),
    );
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeShell(finance: widget.finance)),
      );
    }
  }

  Widget _moneyField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: const [RupiahInputFormatter()],
    decoration: appInput(label, icon, prefix: 'Rp '),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 16),
          const SetupHeader(),
          const SizedBox(height: 24),
          const Text(
            'Siapa nama kamu?',
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: appInput('Contoh: Wisnu', Icons.person_outline_rounded),
          ),
          const SizedBox(height: 24),
          const Text(
            'Batas pengeluaran bulan ini (opsional)',
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _moneyField(_budget, 'Contoh: 2.000.000', Icons.payments_outlined),
          const SizedBox(height: 16),
          const Text(
            'Saldo akun saat ini (opsional)',
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _moneyField(_cash, 'Cash', Icons.payments_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _moneyField(
                  _wallet,
                  'E-Wallet',
                  Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _moneyField(_bank, 'Saldo Bank', Icons.account_balance_outlined),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _submit,
            style: primaryButtonStyle(),
            child: const Text('Simpan & lanjutkan'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}
