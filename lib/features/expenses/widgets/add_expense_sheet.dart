import 'package:flutter/material.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_controls.dart';
import '../../dashboard/viewmodels/finance_viewmodel.dart';
import '../models/expense.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key, required this.finance});
  final FinanceViewModel finance;
  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _name = TextEditingController(), _amount = TextEditingController();
  String _category = 'Makan & minum', _kind = 'food', _source = 'cash';
  final _categories = const [
    ('Makan & minum', 'food'),
    ('Transportasi', 'transport'),
    ('Belanja', 'shopping'),
    ('Tagihan', 'bills'),
    ('Kesehatan', 'health'),
    ('Lainnya', 'other'),
  ];
  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseRupiah(_amount.text);
    if (_name.text.trim().isEmpty || amount <= 0) {
      showMessage(context, 'Lengkapi nama dan nominal pengeluaran.');
      return;
    }
    await widget.finance.addExpense(
      Expense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        category: _category,
        kind: _kind,
        source: _source,
        amount: amount,
        date: DateTime.now(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      22,
      14,
      22,
      MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9DCE6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Catat pengeluaran',
            style: TextStyle(
              fontSize: 21,
              color: ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: appInput('Nama pengeluaran', Icons.edit_note_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            autofocus: true,
            decoration: appInput(
              'Nominal',
              Icons.payments_outlined,
              prefix: 'Rp  ',
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Pilih kategori',
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _categories
                .map(
                  (item) => ChoiceChip(
                    label: Text(item.$1),
                    selected: _category == item.$1,
                    selectedColor: const Color(0xFFDDF8ED),
                    onSelected: (_) => setState(() {
                      _category = item.$1;
                      _kind = item.$2;
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          const Text(
            'Bayar dari',
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children:
                [
                      ('Cash', 'cash', Icons.payments_rounded),
                      (
                        'E-Wallet',
                        'ewallet',
                        Icons.account_balance_wallet_rounded,
                      ),
                      ('Bank', 'bank', Icons.account_balance_rounded),
                    ]
                    .map(
                      (item) => ChoiceChip(
                        avatar: Icon(
                          item.$3,
                          size: 16,
                          color: _source == item.$2
                              ? navy
                              : const Color(0xFF777B90),
                        ),
                        label: Text(item.$1),
                        selected: _source == item.$2,
                        selectedColor: const Color(0xFFDDF8ED),
                        onSelected: (_) => setState(() => _source = item.$2),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 23),
          FilledButton(
            onPressed: _save,
            style: primaryButtonStyle(),
            child: const Text('Simpan pengeluaran'),
          ),
        ],
      ),
    ),
  );
}
