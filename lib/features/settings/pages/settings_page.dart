import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_controls.dart';
import '../../dashboard/viewmodels/finance_viewmodel.dart';
import '../widgets/settings_profile_card.dart';
import '../widgets/settings_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.finance});
  final FinanceViewModel finance;
  Future<void> _editName(BuildContext context) async {
    final field = TextEditingController(text: finance.userName);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah nama'),
        content: TextField(
          controller: field,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama kamu'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (field.text.trim().isEmpty) return;
              await finance.updateName(field.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _editBudget(BuildContext context) async {
    final field = TextEditingController(
      text: formatRupiahInput(finance.budget),
    );
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah budget bulanan'),
        content: TextField(
          controller: field,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          decoration: const InputDecoration(prefixText: 'Rp '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = parseRupiah(field.text);
              if (amount <= 0) return;
              final approved = await showDialog<bool>(
                context: context,
                builder: (dialog) => AlertDialog(
                  title: const Text('Konfirmasi perubahan budget'),
                  content: Text(
                    'Ubah budget bulanan menjadi ${rupiah.format(amount)}? Pengeluaran yang sudah tercatat tidak akan berubah.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Ya, ubah'),
                    ),
                  ],
                ),
              );
              if (approved == true) {
                await finance.updateBudget(amount);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _editBalances(BuildContext context) async {
    final cash = TextEditingController(text: formatRupiahInput(finance.cash)),
        wallet = TextEditingController(
          text: formatRupiahInput(finance.ewallet),
        ),
        bank = TextEditingController(text: formatRupiahInput(finance.bank));
    Widget field(TextEditingController c, String label) => TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: const [RupiahInputFormatter()],
      decoration: InputDecoration(labelText: label, prefixText: 'Rp '),
    );
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Perbarui saldo akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(cash, 'Cash'),
            field(wallet, 'E-Wallet'),
            field(bank, 'Bank'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              await finance.reconcileBalances(
                cashValue: parseRupiah(cash.text),
                ewalletValue: parseRupiah(wallet.text),
                bankValue: parseRupiah(bank.text),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      final data = const JsonEncoder.withIndent(
        '  ',
      ).convert(finance.createBackup());
      final path = await FilePicker.saveFile(
        dialogTitle: 'Simpan backup Dompetku',
        fileName:
            'dompetku-backup-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(utf8.encode(data)),
      );
      if (context.mounted && path != null) {
        showMessage(context, 'Backup berhasil dibuat.');
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'Backup gagal dibuat. Coba lagi.');
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      final file = result?.files.single;
      if (file?.bytes == null || !context.mounted) return;
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Pulihkan backup?'),
          content: Text(
            'Data aplikasi saat ini akan digantikan oleh ${file!.name}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Pulihkan'),
            ),
          ],
        ),
      );
      if (approved != true) return;
      await finance.restoreBackup(
        Map<String, dynamic>.from(jsonDecode(utf8.decode(file!.bytes!)) as Map),
      );
      if (context.mounted) showMessage(context, 'Backup berhasil dipulihkan.');
    } on FormatException {
      if (context.mounted) showMessage(context, 'File backup tidak valid.');
    } catch (_) {
      if (context.mounted) showMessage(context, 'Backup gagal dipulihkan.');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: 25,
            color: ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 25),
        SettingsProfileCard(
          name: finance.userName,
          onEdit: () => _editName(context),
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: 'BUDGET',
          children: [
            SettingsActionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Budget bulanan',
              subtitle: rupiah.format(finance.budget),
              onTap: () => _editBudget(context),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SettingsSection(
          title: 'SALDO AKUN',
          children: [
            SettingsActionTile(
              icon: Icons.sync_alt_rounded,
              title: 'Cash, E-Wallet & Bank',
              subtitle:
                  'Total ${rupiah.format(finance.totalBalance)} • perubahan dicatat',
              onTap: () => _editBalances(context),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SettingsSection(
          title: 'DATA & BACKUP',
          children: [
            SettingsActionTile(
              icon: Icons.ios_share_rounded,
              title: 'Buat backup data',
              subtitle: 'Simpan file backup untuk digunakan kembali',
              onTap: () => _export(context),
            ),
            const Divider(height: 1),
            SettingsActionTile(
              icon: Icons.restore_rounded,
              title: 'Pulihkan backup',
              subtitle: 'Gantikan data dengan file backup',
              onTap: () => _restore(context),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SettingsSection(
          title: 'TENTANG APLIKASI',
          children: [
            const ListTile(
              leading: Icon(Icons.shield_outlined, color: navy),
              title: Text(
                'Data tersimpan di perangkat',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Privat dan aman untuk penggunaan pribadi'),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.info_outline_rounded, color: navy),
              title: Text(
                'Dompetku',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Text('v1.0.0'),
            ),
          ],
        ),
      ],
    ),
  );
}
