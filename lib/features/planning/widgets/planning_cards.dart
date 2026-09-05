import 'package:flutter/material.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../models/installment.dart';
import '../models/savings.dart';

class InstallmentPlanCard extends StatelessWidget {
  const InstallmentPlanCard({
    super.key,
    required this.plan,
    required this.onPay,
    required this.onAddPayment,
    required this.onDelete,
  });
  final InstallmentPlan plan;
  final VoidCallback onPay;
  final VoidCallback onAddPayment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final next = plan.payments.where((item) => !item.paid).firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car_rounded, color: navy),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                Text(
                  '${plan.paidCount}/${plan.payments.length}',
                  style: const TextStyle(
                    color: Color(0xFF777B90),
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFD94B3D),
                  ),
                  tooltip: 'Hapus cicilan',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total: ${rupiah.format(plan.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
                Text(
                  'Terbayar: ${rupiah.format(plan.paidAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF168260),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sisa: ${rupiah.format(plan.remainingAmount)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF777B90)),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: plan.payments.isEmpty
                  ? 0
                  : plan.paidCount / plan.payments.length,
              borderRadius: BorderRadius.circular(8),
              minHeight: 7,
              valueColor: const AlwaysStoppedAnimation(mint),
            ),
            const SizedBox(height: 10),
            if (next != null)
              Row(
                children: [
                  Text(
                    'Berikutnya: ${rupiah.format(next.amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${next.dueDate.day}/${next.dueDate.month}/${next.dueDate.year}',
                    style: const TextStyle(
                      color: Color(0xFF777B90),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            if (next != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Bayar cicilan'),
                ),
              )
            else
              const Text(
                'Cicilan selesai',
                style: TextStyle(
                  color: Color(0xFF168260),
                  fontWeight: FontWeight.w700,
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAddPayment,
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('Tambah jadwal pembayaran'),
              ),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Lihat jadwal pembayaran',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              children: plan.payments
                  .map(
                    (payment) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      color: const Color(0xFFF7F8FC),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          payment.paid
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          color: payment.paid
                              ? const Color(0xFF168260)
                              : const Color(0xFF85899B),
                        ),
                        title: Text(
                          'Bayar ${payment.sequence} · ${rupiah.format(payment.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year}${payment.paid ? ' · Lunas' : ' · Belum dibayar'}',
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SavingsGoalCard extends StatelessWidget {
  const SavingsGoalCard({
    super.key,
    required this.goal,
    required this.onDeposit,
  });
  final SavingsGoal goal;
  final VoidCallback onDeposit;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_rounded, color: navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
              Text(
                rupiah.format(goal.balance),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
            ],
          ),
          if (goal.targetAmount != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: goal.progress,
              borderRadius: BorderRadius.circular(8),
              minHeight: 7,
              valueColor: const AlwaysStoppedAnimation(mint),
            ),
            const SizedBox(height: 5),
            Text(
              'Target ${rupiah.format(goal.targetAmount!)}',
              style: const TextStyle(color: Color(0xFF777B90), fontSize: 12),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDeposit,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Tambah setoran'),
            ),
          ),
        ],
      ),
    ),
  );
}
