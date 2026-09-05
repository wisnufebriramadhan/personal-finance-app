import 'package:flutter/material.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../../core/widgets/app_controls.dart';
import '../../dashboard/viewmodels/finance_viewmodel.dart';
import '../models/installment.dart';
import '../models/savings.dart';
import '../widgets/planning_cards.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key, required this.finance});
  final FinanceViewModel finance;
  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _addInstallment() async {
    final name = TextEditingController();
    final amount = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah cicilan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: appInput(
                'Nama cicilan',
                Icons.directions_car_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              decoration: appInput(
                'Nominal pembayaran',
                Icons.payments_outlined,
                prefix: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              name.text.trim().isNotEmpty && parseRupiah(amount.text) > 0,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    await widget.finance.addInstallmentPlan(
      InstallmentPlan(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(),
        provider: '',
        defaultSource: 'bank',
        payments: [
          InstallmentPayment(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            sequence: 1,
            dueDate: DateTime.now(),
            amount: parseRupiah(amount.text),
          ),
        ],
      ),
    );
  }

  Future<void> _addSavings() async {
    final name = TextEditingController();
    final target = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah tabungan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: appInput('Nama tabungan', Icons.savings_outlined),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: target,
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              decoration: appInput(
                'Target (opsional)',
                Icons.flag_outlined,
                prefix: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, name.text.trim().isNotEmpty),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final targetValue = parseRupiah(target.text);
    await widget.finance.addSavingsGoal(
      SavingsGoal(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(),
        targetAmount: targetValue > 0 ? targetValue : null,
        entries: const [],
      ),
    );
  }

  Future<void> _pay(InstallmentPlan plan, InstallmentPayment payment) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['cash', 'ewallet', 'bank']
              .map(
                (value) => ListTile(
                  title: Text(
                    value == 'cash'
                        ? 'Cash'
                        : value == 'ewallet'
                        ? 'E-Wallet'
                        : 'Bank',
                  ),
                  onTap: () => Navigator.pop(context, value),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (source != null) {
      try {
        await widget.finance.payInstallment(
          planId: plan.id,
          paymentId: payment.id,
          source: source,
        );
      } on InsufficientBalanceException {
        if (mounted) showMessage(context, 'Saldo sumber dana tidak mencukupi.');
      }
    }
  }

  Future<void> _addPayment(InstallmentPlan plan) async {
    final amount = TextEditingController();
    DateTime dueDate = DateTime.now();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Tambah Bayar ${plan.payments.length + 1}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                decoration: appInput(
                  'Nominal pembayaran',
                  Icons.payments_outlined,
                  prefix: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Jatuh tempo'),
                subtitle: Text(
                  '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDate: dueDate,
                  );
                  if (picked != null) setDialogState(() => dueDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, parseRupiah(amount.text) > 0),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await widget.finance.addInstallmentPayment(
        planId: plan.id,
        amount: parseRupiah(amount.text),
        dueDate: dueDate,
      );
    }
  }

  Future<void> _deletePlan(InstallmentPlan plan) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus cicilan?'),
        content: Text(
          'Rencana "${plan.name}" dan seluruh jadwal pembayarannya akan dihapus.',
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
    );
    if (approved == true) await widget.finance.deleteInstallmentPlan(plan.id);
  }

  Future<void> _deposit(SavingsGoal goal) async {
    final amount = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah setoran'),
        content: TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          decoration: appInput(
            'Nominal setoran',
            Icons.payments_outlined,
            prefix: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, parseRupiah(amount.text) > 0),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved == true) {
      try {
        await widget.finance.addSavingsEntry(
          goalId: goal.id,
          entry: SavingsEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            type: 'deposit',
            contributor: 'Saya',
            amount: parseRupiah(amount.text),
            date: DateTime.now(),
            source: 'bank',
          ),
        );
      } on InsufficientBalanceException {
        if (mounted) showMessage(context, 'Saldo Bank tidak mencukupi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.finance,
    builder: (context, child) => SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Rencana keuangan',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _tabs.index == 0 ? _addInstallment() : _addSavings(),
                  icon: const Icon(Icons.add_circle_rounded),
                  tooltip: 'Tambah',
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Cicilan'),
              Tab(text: 'Tabungan'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _InstallmentList(
                  finance: widget.finance,
                  onPay: _pay,
                  onAddPayment: _addPayment,
                  onDelete: _deletePlan,
                ),
                _SavingsList(finance: widget.finance, onDeposit: _deposit),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _InstallmentList extends StatelessWidget {
  const _InstallmentList({
    required this.finance,
    required this.onPay,
    required this.onAddPayment,
    required this.onDelete,
  });
  final FinanceViewModel finance;
  final Future<void> Function(InstallmentPlan, InstallmentPayment) onPay;
  final Future<void> Function(InstallmentPlan) onAddPayment;
  final Future<void> Function(InstallmentPlan) onDelete;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: finance.installmentPlans.isEmpty
        ? [const _EmptyPlan(text: 'Belum ada cicilan')]
        : finance.installmentPlans.map((plan) {
            final payment = plan.payments
                .where((item) => !item.paid)
                .firstOrNull;
            return InstallmentPlanCard(
              plan: plan,
              onPay: payment == null ? () {} : () => onPay(plan, payment),
              onAddPayment: () => onAddPayment(plan),
              onDelete: () => onDelete(plan),
            );
          }).toList(),
  );
}

class _SavingsList extends StatelessWidget {
  const _SavingsList({required this.finance, required this.onDeposit});
  final FinanceViewModel finance;
  final Future<void> Function(SavingsGoal) onDeposit;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: finance.savingsGoals.isEmpty
        ? [const _EmptyPlan(text: 'Belum ada tabungan')]
        : finance.savingsGoals
              .map(
                (goal) => SavingsGoalCard(
                  goal: goal,
                  onDeposit: () => onDeposit(goal),
                ),
              )
              .toList(),
  );
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Column(
        children: [
          const Icon(
            Icons.event_note_outlined,
            size: 48,
            color: Color(0xFF9AA0B6),
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Color(0xFF777B90))),
        ],
      ),
    ),
  );
}
