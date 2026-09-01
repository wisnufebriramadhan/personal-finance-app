import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const navy = Color(0xFF121A43),
    mint = Color(0xFF72E3BA),
    ink = Color(0xFF1E2340),
    bg = Color(0xFFF7F8FC);
final money = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = NumberFormat.decimalPattern(
      'id_ID',
    ).format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String rupiahInput(double value) =>
    NumberFormat.decimalPattern('id_ID').format(value.round());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Dompetku',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: navy),
    ),
    home: const Splash(),
  );
}

class Expense {
  Expense(
    this.id,
    this.name,
    this.category,
    this.kind,
    this.source,
    this.amount,
    this.date,
  );
  final String id, name, category, kind, source;
  final double amount;
  final DateTime date;
  Map<String, dynamic> json() => {
    'id': id,
    'name': name,
    'category': category,
    'kind': kind,
    'source': source,
    'amount': amount,
    'date': date.toIso8601String(),
  };
  factory Expense.from(Map<String, dynamic> x) => Expense(
    x['id'],
    x['name'],
    x['category'],
    x['kind'],
    x['source'] ?? 'cash',
    (x['amount'] as num).toDouble(),
    DateTime.parse(x['date']),
  );
}

class Store extends ChangeNotifier {
  double budget = 0;
  double cash = 0, ewallet = 0, bank = 0;
  String userName = 'Teman Finansial';
  bool onboarded = false;
  List<Expense> items = [];
  bool get ready => onboarded || budget > 0;
  double get spent => items.fold(0, (s, x) => s + x.amount);
  double get left => budget - spent;
  double get pct => budget == 0 ? 0 : (spent / budget).clamp(0, 1);
  double get totalBalance => cash + ewallet + bank;
  double balanceOf(String source) => source == 'cash'
      ? cash
      : source == 'ewallet'
      ? ewallet
      : bank;
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    budget = p.getDouble('budget') ?? 0;
    cash = p.getDouble('cash') ?? 0;
    ewallet = p.getDouble('ewallet') ?? 0;
    bank = p.getDouble('bank') ?? 0;
    userName = p.getString('user_name') ?? 'Teman Finansial';
    onboarded = p.getBool('onboarded') ?? budget > 0;
    items =
        (jsonDecode(p.getString('items') ?? '[]') as List)
            .map((x) => Expense.from(x))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('budget', budget);
    await p.setDouble('cash', cash);
    await p.setDouble('ewallet', ewallet);
    await p.setDouble('bank', bank);
    await p.setString('user_name', userName);
    await p.setBool('onboarded', onboarded);
    await p.setString('items', jsonEncode(items.map((x) => x.json()).toList()));
  }

  Map<String, dynamic> backupData() => {
    'app': 'Dompetku',
    'version': 1,
    'created_at': DateTime.now().toIso8601String(),
    'data': {
      'budget': budget,
      'cash': cash,
      'ewallet': ewallet,
      'bank': bank,
      'user_name': userName,
      'onboarded': onboarded,
      'items': items.map((item) => item.json()).toList(),
    },
  };

  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    final raw = backup['data'];
    if (backup['app'] != 'Dompetku' || raw is! Map) {
      throw const FormatException('File bukan backup Dompetku yang valid.');
    }
    final data = Map<String, dynamic>.from(raw);
    double number(String key) => (data[key] as num?)?.toDouble() ?? 0;
    final rawItems = data['items'];
    if (rawItems is! List) {
      throw const FormatException('Isi backup tidak lengkap.');
    }
    budget = number('budget');
    cash = number('cash');
    ewallet = number('ewallet');
    bank = number('bank');
    userName = (data['user_name'] as String?)?.trim().isNotEmpty == true
        ? data['user_name'] as String
        : 'Teman Finansial';
    onboarded = data['onboarded'] as bool? ?? true;
    items =
        rawItems
            .map((item) => Expense.from(Map<String, dynamic>.from(item as Map)))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await save();
  }

  Future<void> setBudget(double v) async {
    budget = v;
    notifyListeners();
    await save();
  }

  Future<void> setUserName(String value) async {
    userName = value.trim();
    notifyListeners();
    await save();
  }

  Future<void> setBalances({
    required double cashValue,
    required double ewalletValue,
    required double bankValue,
  }) async {
    cash = cashValue;
    ewallet = ewalletValue;
    bank = bankValue;
    notifyListeners();
    await save();
  }

  Future<void> completeOnboarding() async {
    onboarded = true;
    notifyListeners();
    await save();
  }

  void _changeBalance(String source, double delta) {
    if (source == 'cash') {
      cash += delta;
    } else if (source == 'ewallet') {
      ewallet += delta;
    } else {
      bank += delta;
    }
  }

  Future<void> add(Expense v) async {
    items.insert(0, v);
    _changeBalance(v.source, -v.amount);
    notifyListeners();
    await save();
  }

  Future<void> delete(String id) async {
    final item = items.cast<Expense?>().firstWhere(
      (x) => x?.id == id,
      orElse: () => null,
    );
    if (item == null) return;
    items.removeWhere((x) => x.id == id);
    _changeBalance(item.source, item.amount);
    notifyListeners();
    await save();
  }
}

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    go();
  }

  Future<void> go() async {
    final s = Store();
    await s.load();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => s.ready ? Home(s) : Setup(s)),
      );
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: navy,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/app_icon/dompetku_icon.png',
              width: 104,
              height: 104,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'dompetku',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kelola uangmu, lebih tenang.',
            style: TextStyle(color: Color(0xFFBEC8EE)),
          ),
        ],
      ),
    ),
  );
}

class Setup extends StatefulWidget {
  const Setup(this.s, {super.key});
  final Store s;
  @override
  State<Setup> createState() => _SetupState();
}

class _SetupState extends State<Setup> {
  final t = TextEditingController();
  final ownerName = TextEditingController();
  final cash = TextEditingController(),
      wallet = TextEditingController(),
      bank = TextEditingController();
  Future<void> submit() async {
    if (ownerName.text.trim().isEmpty) {
      msg(context, 'Masukkan nama kamu terlebih dahulu.');
      return;
    }
    final n = double.tryParse(t.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (n > 0) await widget.s.setBudget(n);
    await widget.s.setUserName(ownerName.text);
    double value(TextEditingController field) =>
        double.tryParse(field.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    await widget.s.setBalances(
      cashValue: value(cash),
      ewalletValue: value(wallet),
      bankValue: value(bank),
    );
    await widget.s.completeOnboarding();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Home(widget.s)),
      );
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 16),
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
            'Saldo nyata mencerminkan uang yang tersedia. Budget adalah batas belanja yang kamu rencanakan—keduanya tidak harus sama.',
            style: TextStyle(color: Color(0xFF6D7187), height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Siapa nama kamu?',
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ownerName,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: input('Contoh: Wisnu', Icons.person_outline_rounded),
          ),
          const SizedBox(height: 24),
          const Text(
            'Batas pengeluaran bulan ini (opsional)',
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: t,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            autofocus: true,
            decoration: input(
              'Contoh: 2.000.000',
              Icons.payments_outlined,
              prefix: 'Rp  ',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Saldo nyata saat ini (opsional)',
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: cash,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                  decoration: input(
                    'Cash',
                    Icons.payments_outlined,
                    prefix: 'Rp ',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: wallet,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                  decoration: input(
                    'E-Wallet',
                    Icons.account_balance_wallet_outlined,
                    prefix: 'Rp ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: bank,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            decoration: input(
              'Saldo Bank',
              Icons.account_balance_outlined,
              prefix: 'Rp ',
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: submit,
            style: button(),
            child: const Text('Simpan & lanjutkan'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

class Home extends StatefulWidget {
  const Home(this.s, {super.key});
  final Store s;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  DateTime? _lastBackPress;

  void _handleExit() {
    final now = DateTime.now();
    final pressedRecently =
        _lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2);
    if (pressedRecently) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tekan kembali sekali lagi untuk keluar'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void add() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => AddSheet(widget.s),
  );
  @override
  Widget build(BuildContext c) {
    return AnimatedBuilder(
      animation: widget.s,
      builder: (context, child) {
        final page = switch (tab) {
          0 => Dashboard(widget.s, add),
          1 => Insights(widget.s),
          _ => Settings(widget.s),
        };
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _handleExit();
          },
          child: Scaffold(
            extendBody: true,
            body: page,
            floatingActionButton: tab == 0
                ? FloatingActionButton(
                    onPressed: add,
                    backgroundColor: mint,
                    foregroundColor: navy,
                    tooltip: 'Catat pengeluaran',
                    child: const Icon(Icons.add_rounded, size: 28),
                  )
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: FloatingBottomMenu(
              selectedIndex: tab,
              onItemTapped: (value) => setState(() => tab = value),
            ),
          ),
        );
      },
    );
  }
}

class FloatingBottomMenu extends StatelessWidget {
  const FloatingBottomMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25121A43),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingMenuItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              selected: selectedIndex == 0,
              onTap: () => onItemTapped(0),
            ),
            FloatingMenuItem(
              icon: Icons.pie_chart_rounded,
              label: 'Analisis',
              selected: selectedIndex == 1,
              onTap: () => onItemTapped(1),
            ),
            FloatingMenuItem(
              icon: Icons.tune_rounded,
              label: 'Atur',
              selected: selectedIndex == 2,
              onTap: () => onItemTapped(2),
            ),
          ],
        ),
      ),
    ),
  );
}

class FloatingMenuItem extends StatelessWidget {
  const FloatingMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: selected ? 13 : 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE5F9F0) : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: selected ? navy : const Color(0xFF85899B),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: selected
                ? Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    ),
  );
}

class Dashboard extends StatelessWidget {
  const Dashboard(this.s, this.add, {super.key});
  final Store s;
  final VoidCallback add;
  @override
  Widget build(BuildContext c) {
    final month = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: navy,
                child: Text(
                  'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat datang,',
                    style: TextStyle(color: Color(0xFF777B90), fontSize: 12),
                  ),
                  Text(
                    s.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.notifications_none_rounded),
            ],
          ),
          const SizedBox(height: 27),
          Text(
            month[0].toUpperCase() + month.substring(1),
            style: const TextStyle(
              color: Color(0xFF73778B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          BudgetCard(s),
          const SizedBox(height: 16),
          BalanceOverview(s),
          const SizedBox(height: 25),
          Row(
            children: [
              const Text(
                'Pengeluaran terbaru',
                style: TextStyle(
                  fontSize: 18,
                  color: ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  c,
                  MaterialPageRoute(builder: (_) => All(s)),
                ),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (s.items.isEmpty)
            Empty(add)
          else
            ...s.items.take(4).map((x) => ExpenseTile(x, () => s.delete(x.id))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F8F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF168260),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    s.pct > .8
                        ? 'Budget sudah mendekati batas. Prioritaskan pengeluaran yang penting, ya.'
                        : 'Kebiasaan kecil yang konsisten adalah kunci kondisi finansial yang lebih sehat.',
                    style: const TextStyle(
                      color: Color(0xFF276250),
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  const BudgetCard(this.s, {super.key});
  final Store s;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(25),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33121A43),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.budget > 0 ? 'Sisa budget' : 'Budget bulanan',
              style: TextStyle(
                color: Color(0xFFBFC7EE),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              s.budget > 0 ? '${(s.pct * 100).round()}% terpakai' : 'Opsional',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          s.budget > 0 ? money.format(s.left) : 'Belum diatur',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            value: s.pct,
            minHeight: 9,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(
              s.pct > .8 ? const Color(0xFFFFB0A1) : mint,
            ),
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Text(
              s.budget > 0
                  ? 'Terpakai ${money.format(s.spent)}'
                  : 'Tetap bisa mencatat',
              style: const TextStyle(color: Color(0xFFCBD1EF), fontSize: 12),
            ),
            const Spacer(),
            Text(
              s.budget > 0 ? 'dari ${money.format(s.budget)}' : 'Atur nanti',
              style: const TextStyle(color: Color(0xFFCBD1EF), fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

class BalanceOverview extends StatelessWidget {
  const BalanceOverview(this.s, {super.key});
  final Store s;
  @override
  Widget build(BuildContext c) => Container(
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
              'Saldo nyata',
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              money.format(s.totalBalance),
              style: const TextStyle(color: navy, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            BalanceItem(
              'Cash',
              s.cash,
              Icons.payments_rounded,
              const Color(0xFFFFF0D9),
            ),
            const SizedBox(width: 8),
            BalanceItem(
              'E-Wallet',
              s.ewallet,
              Icons.account_balance_wallet_rounded,
              const Color(0xFFE7F1FF),
            ),
            const SizedBox(width: 8),
            BalanceItem(
              'Bank',
              s.bank,
              Icons.account_balance_rounded,
              const Color(0xFFE8F8F1),
            ),
          ],
        ),
      ],
    ),
  );
}

class BalanceItem extends StatelessWidget {
  const BalanceItem(this.label, this.value, this.icon, this.color, {super.key});
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext c) => Expanded(
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
            money.format(value),
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

class Empty extends StatelessWidget {
  const Empty(this.add, {super.key});
  final VoidCallback add;
  @override
  Widget build(BuildContext c) => Container(
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
        TextButton(onPressed: add, child: const Text('Catat sekarang')),
      ],
    ),
  );
}

final icons = {
  'food': Icons.restaurant_rounded,
  'transport': Icons.directions_car_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'bills': Icons.receipt_long_rounded,
  'health': Icons.favorite_rounded,
  'other': Icons.more_horiz_rounded,
};
String sourceName(String source) => source == 'cash'
    ? 'Cash'
    : source == 'ewallet'
    ? 'E-Wallet'
    : 'Bank';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile(this.x, this.del, {super.key});
  final Expense x;
  final VoidCallback del;
  @override
  Widget build(BuildContext c) => Dismissible(
    key: ValueKey(x.id),
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) async {
      final approved = await showDialog<bool>(
        context: c,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Hapus transaksi?'),
          content: Text(
            '"${x.name}" akan dihapus dan saldo ${sourceName(x.source)} akan dikembalikan sebesar ${money.format(x.amount)}.',
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
      return approved ?? false;
    },
    onDismissed: (_) => del(),
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
            child: Icon(icons[x.kind], color: navy, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  x.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${x.category} • ${sourceName(x.source)} • ${DateFormat('d MMM', 'id_ID').format(x.date)}',
                  style: const TextStyle(
                    color: Color(0xFF8B8FA2),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-${money.format(x.amount)}',
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

class AddSheet extends StatefulWidget {
  const AddSheet(this.s, {super.key});
  final Store s;
  @override
  State<AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<AddSheet> {
  final name = TextEditingController(), amount = TextEditingController();
  String cat = 'Makan & minum', kind = 'food', source = 'cash';
  final cats = [
    ('Makan & minum', 'food'),
    ('Transportasi', 'transport'),
    ('Belanja', 'shopping'),
    ('Tagihan', 'bills'),
    ('Kesehatan', 'health'),
    ('Lainnya', 'other'),
  ];
  Future<void> save() async {
    final n =
        double.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (name.text.trim().isEmpty || n <= 0) {
      msg(context, 'Lengkapi nama dan nominal pengeluaran.');
      return;
    }
    unawaited(
      widget.s.add(
        Expense(
          DateTime.now().microsecondsSinceEpoch.toString(),
          name.text.trim(),
          cat,
          kind,
          source,
          n,
          DateTime.now(),
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c) => Padding(
    padding: EdgeInsets.fromLTRB(
      22,
      14,
      22,
      MediaQuery.of(c).viewInsets.bottom + 24,
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
            controller: name,
            textCapitalization: TextCapitalization.sentences,
            decoration: input('Nama pengeluaran', Icons.edit_note_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            autofocus: true,
            decoration: input(
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
            children: cats
                .map(
                  (v) => ChoiceChip(
                    label: Text(v.$1),
                    selected: cat == v.$1,
                    selectedColor: const Color(0xFFDDF8ED),
                    onSelected: (_) => setState(() {
                      cat = v.$1;
                      kind = v.$2;
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
                      (v) => ChoiceChip(
                        avatar: Icon(
                          v.$3,
                          size: 16,
                          color: source == v.$2
                              ? navy
                              : const Color(0xFF777B90),
                        ),
                        label: Text(v.$1),
                        selected: source == v.$2,
                        selectedColor: const Color(0xFFDDF8ED),
                        onSelected: (_) => setState(() => source = v.$2),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 23),
          FilledButton(
            onPressed: save,
            style: button(),
            child: const Text('Simpan pengeluaran'),
          ),
        ],
      ),
    ),
  );
}

class All extends StatelessWidget {
  const All(this.s, {super.key});
  final Store s;
  @override
  Widget build(BuildContext c) => AnimatedBuilder(
    animation: s,
    builder: (context, child) => Scaffold(
      appBar: AppBar(
        title: const Text(
          'Semua pengeluaran',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: s.items
            .map((x) => ExpenseTile(x, () => s.delete(x.id)))
            .toList(),
      ),
    ),
  );
}

class Insights extends StatelessWidget {
  const Insights(this.s, {super.key});
  final Store s;
  @override
  Widget build(BuildContext c) {
    final g = <String, double>{};
    for (final x in s.items) {
      g[x.category] = (g[x.category] ?? 0) + x.amount;
    }
    final list = g.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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
                Metric(
                  'Total keluar',
                  money.format(s.spent),
                  const Color(0xFFFFEEE9),
                ),
                const SizedBox(width: 12),
                Metric(
                  'Transaksi',
                  '${s.items.length}',
                  const Color(0xFFE8F8F1),
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
          if (list.isEmpty)
            const EmptyInsight()
          else
            ...list.map(
              (v) => Container(
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
                          v.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          money.format(v.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: s.spent == 0 ? 0 : v.value / s.spent,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(9),
                      backgroundColor: const Color(0xFFF0F1F6),
                      valueColor: const AlwaysStoppedAnimation(mint),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Metric extends StatelessWidget {
  const Metric(this.label, this.value, this.color, {super.key});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext c) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF74788C), fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

class EmptyInsight extends StatelessWidget {
  const EmptyInsight({super.key});
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      children: [
        Icon(Icons.pie_chart_outline, size: 42, color: Color(0xFF9AA0B6)),
        SizedBox(height: 10),
        Text(
          'Data analisis akan tampil setelah kamu mencatat pengeluaran.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF74788C), fontSize: 12),
        ),
      ],
    ),
  );
}

class Settings extends StatelessWidget {
  const Settings(this.s, {super.key});
  final Store s;
  void editName(BuildContext c) {
    final field = TextEditingController(text: s.userName);
    showDialog(
      context: c,
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
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (field.text.trim().isEmpty) return;
              await s.setUserName(field.text);
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void edit(BuildContext c) {
    final t = TextEditingController(text: rupiahInput(s.budget));
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Ubah budget bulanan'),
        content: TextField(
          controller: t,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          decoration: const InputDecoration(prefixText: 'Rp '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final n =
                  double.tryParse(t.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              if (n <= 0) return;
              final approved = await showDialog<bool>(
                context: c,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Konfirmasi perubahan budget'),
                  content: Text(
                    'Ubah budget bulanan menjadi ${money.format(n)}? Pengeluaran yang sudah tercatat tidak akan berubah.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Ya, ubah'),
                    ),
                  ],
                ),
              );
              if (approved == true) {
                await s.setBudget(n);
                if (c.mounted) Navigator.pop(c);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void editBalances(BuildContext c) {
    final cash = TextEditingController(text: rupiahInput(s.cash));
    final wallet = TextEditingController(text: rupiahInput(s.ewallet));
    final bank = TextEditingController(text: rupiahInput(s.bank));
    double value(TextEditingController field) =>
        double.tryParse(field.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Perbarui saldo nyata'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cash,
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Cash',
                prefixText: 'Rp ',
              ),
            ),
            TextField(
              controller: wallet,
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'E-Wallet',
                prefixText: 'Rp ',
              ),
            ),
            TextField(
              controller: bank,
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Bank',
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              await s.setBalances(
                cashValue: value(cash),
                ewalletValue: value(wallet),
                bankValue: value(bank),
              );
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> exportBackup(BuildContext c) async {
    try {
      final content = const JsonEncoder.withIndent(
        '  ',
      ).convert(s.backupData());
      final fileName =
          'dompetku-backup-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.json';
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Simpan backup Dompetku',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(utf8.encode(content)),
      );
      if (!c.mounted || savedPath == null) return;
      msg(c, 'Backup berhasil dibuat. Simpan file ini di tempat aman.');
    } catch (_) {
      if (c.mounted) msg(c, 'Backup gagal dibuat. Coba lagi.');
    }
  }

  Future<void> importBackup(BuildContext c) async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      final file = picked?.files.single;
      final bytes = file?.bytes;
      if (!c.mounted || file == null || bytes == null) return;
      final approved = await showDialog<bool>(
        context: c,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pulihkan backup?'),
          content: Text(
            'Data aplikasi saat ini akan digantikan oleh ${file.name}. Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Pulihkan'),
            ),
          ],
        ),
      );
      if (approved != true) return;
      await s.restoreBackup(
        Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
      );
      if (c.mounted) msg(c, 'Backup berhasil dipulihkan.');
    } on FormatException {
      if (c.mounted) msg(c, 'File backup tidak valid.');
    } catch (_) {
      if (c.mounted) msg(c, 'Backup gagal dipulihkan.');
    }
  }

  @override
  Widget build(BuildContext c) => SafeArea(
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
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: mint,
                child: Icon(Icons.person_rounded, color: navy),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Mulai perjalanan finansialmu',
                      style: TextStyle(color: Color(0xFFBFC7EE), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => editName(c),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Ubah nama',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'BUDGET',
          style: TextStyle(
            color: Color(0xFF85899B),
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            onTap: () => edit(c),
            leading: const Icon(
              Icons.account_balance_wallet_outlined,
              color: navy,
            ),
            title: const Text(
              'Budget bulanan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(money.format(s.budget)),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'SALDO NYATA',
          style: TextStyle(
            color: Color(0xFF85899B),
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            onTap: () => editBalances(c),
            leading: const Icon(Icons.sync_alt_rounded, color: navy),
            title: const Text(
              'Cash, E-Wallet & Bank',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('Total ${money.format(s.totalBalance)}'),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'DATA & BACKUP',
          style: TextStyle(
            color: Color(0xFF85899B),
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              ListTile(
                onTap: () => exportBackup(c),
                leading: const Icon(Icons.ios_share_rounded, color: navy),
                title: const Text(
                  'Buat backup data',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Simpan file backup untuk digunakan kembali',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
              const Divider(height: 1),
              ListTile(
                onTap: () => importBackup(c),
                leading: const Icon(Icons.restore_rounded, color: navy),
                title: const Text(
                  'Pulihkan backup',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Gantikan data dengan file backup'),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'TENTANG APLIKASI',
          style: TextStyle(
            color: Color(0xFF85899B),
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            children: [
              ListTile(
                leading: Icon(Icons.shield_outlined, color: navy),
                title: Text(
                  'Data tersimpan di perangkat',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Privat dan aman untuk penggunaan pribadi'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.info_outline_rounded, color: navy),
                title: Text(
                  'Dompetku',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: Text('v1.0.0'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

InputDecoration input(String hint, IconData icon, {String? prefix}) =>
    InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixIcon: Icon(icon, color: const Color(0xFF777B90)),
      filled: true,
      fillColor: const Color(0xFFF7F8FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
ButtonStyle button() => FilledButton.styleFrom(
  backgroundColor: navy,
  minimumSize: const Size.fromHeight(56),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  textStyle: const TextStyle(fontWeight: FontWeight.w700),
);
void msg(BuildContext c, String s) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s)));
