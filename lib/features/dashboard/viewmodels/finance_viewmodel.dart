import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../expenses/models/expense.dart';
import '../../planning/models/installment.dart';
import '../../planning/models/savings.dart';

class FinanceViewModel extends ChangeNotifier {
  double _legacyBudget = 0;
  Map<String, double> monthlyBudgets = {};
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  double cash = 0;
  double ewallet = 0;
  double bank = 0;
  String userName = 'Teman Finansial';
  bool onboarded = false;
  List<Expense> items = [];
  List<InstallmentPlan> installmentPlans = [];
  List<SavingsGoal> savingsGoals = [];

  String get selectedMonthKey => _monthKey(selectedMonth);
  double get budget => monthlyBudgets[selectedMonthKey] ?? _legacyBudget;
  List<Expense> get periodItems =>
      items.where((item) => _isInSelectedMonth(item.date)).toList();
  bool get isReady => onboarded || budget > 0;
  double get spent => periodItems
      .where((item) => !item.isAdjustment)
      .fold(0, (sum, item) => sum + item.amount);
  double get remainingBudget => budget - spent;
  double get budgetProgress => budget == 0 ? 0 : (spent / budget).clamp(0, 1);
  double get totalBalance => cash + ewallet + bank;

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
  bool _isInSelectedMonth(DateTime date) =>
      date.year == selectedMonth.year && date.month == selectedMonth.month;
  double balanceFor(String source) => switch (source) {
    'cash' => cash,
    'ewallet' => ewallet,
    _ => bank,
  };
  void selectMonth(DateTime value) {
    selectedMonth = DateTime(value.year, value.month);
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _legacyBudget = prefs.getDouble('budget') ?? 0;
    final rawBudgets = prefs.getString('monthly_budgets');
    if (rawBudgets != null) {
      final decoded = jsonDecode(rawBudgets);
      if (decoded is Map) {
        monthlyBudgets = decoded.map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        );
      }
    }
    cash = prefs.getDouble('cash') ?? 0;
    ewallet = prefs.getDouble('ewallet') ?? 0;
    bank = prefs.getDouble('bank') ?? 0;
    userName = prefs.getString('user_name') ?? userName;
    onboarded = prefs.getBool('onboarded') ?? budget > 0;
    items =
        (jsonDecode(prefs.getString('items') ?? '[]') as List)
            .map(
              (item) =>
                  Expense.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    installmentPlans = _decodeList(
      prefs.getString('installment_plans') ?? '[]',
      (item) => InstallmentPlan.fromJson(item),
    );
    savingsGoals = _decodeList(
      prefs.getString('savings_goals') ?? '[]',
      (item) => SavingsGoal.fromJson(item),
    );
    notifyListeners();
  }

  List<T> _decodeList<T>(String raw, T Function(Map<String, dynamic>) parse) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map((item) => parse(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget', _legacyBudget);
    await prefs.setString('monthly_budgets', jsonEncode(monthlyBudgets));
    await prefs.setDouble('cash', cash);
    await prefs.setDouble('ewallet', ewallet);
    await prefs.setDouble('bank', bank);
    await prefs.setString('user_name', userName);
    await prefs.setBool('onboarded', onboarded);
    await prefs.setString(
      'items',
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(
      'installment_plans',
      jsonEncode(installmentPlans.map((plan) => plan.toJson()).toList()),
    );
    await prefs.setString(
      'savings_goals',
      jsonEncode(savingsGoals.map((goal) => goal.toJson()).toList()),
    );
  }

  Future<void> setup({
    required String name,
    required double budgetValue,
    required double cashValue,
    required double ewalletValue,
    required double bankValue,
  }) async {
    userName = name.trim();
    _legacyBudget = budgetValue;
    monthlyBudgets[selectedMonthKey] = budgetValue;
    cash = cashValue;
    ewallet = ewalletValue;
    bank = bankValue;
    onboarded = true;
    notifyListeners();
    await _persist();
  }

  Future<void> updateName(String value) async {
    userName = value.trim();
    notifyListeners();
    await _persist();
  }

  Future<void> updateBudget(double value) async {
    monthlyBudgets[selectedMonthKey] = value;
    notifyListeners();
    await _persist();
  }

  Future<void> reconcileBalances({
    required double cashValue,
    required double ewalletValue,
    required double bankValue,
  }) async {
    final targets = {
      'cash': cashValue,
      'ewallet': ewalletValue,
      'bank': bankValue,
    };
    for (final entry in targets.entries) {
      final difference = balanceFor(entry.key) - entry.value;
      if (difference == 0) continue;
      items.insert(
        0,
        Expense(
          id: DateTime.now().microsecondsSinceEpoch.toString() + entry.key,
          name: 'Penyesuaian saldo ${_accountName(entry.key)}',
          category: 'Penyesuaian saldo',
          kind: 'other',
          source: entry.key,
          amount: difference,
          date: DateTime.now(),
          type: 'adjustment',
        ),
      );
      _changeBalance(entry.key, -difference);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> addExpense(Expense expense) async {
    _requireSufficientBalance(expense.source, expense.amount);
    items.insert(0, expense);
    _changeBalance(expense.source, -expense.amount);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteExpense(String id) async {
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final expense = items.removeAt(index);
    _changeBalance(expense.source, expense.amount);
    _markLinkedPaymentUnpaid(id);
    notifyListeners();
    await _persist();
  }

  Future<void> addInstallmentPlan(InstallmentPlan plan) async {
    installmentPlans = [...installmentPlans, plan];
    notifyListeners();
    await _persist();
  }

  Future<void> addInstallmentPayment({
    required String planId,
    required double amount,
    required DateTime dueDate,
  }) async {
    final index = installmentPlans.indexWhere((plan) => plan.id == planId);
    if (index < 0) return;
    final plan = installmentPlans[index];
    final payment = InstallmentPayment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sequence: plan.payments.length + 1,
      dueDate: dueDate,
      amount: amount,
    );
    installmentPlans = [...installmentPlans]
      ..[index] = InstallmentPlan(
        id: plan.id,
        name: plan.name,
        provider: plan.provider,
        defaultSource: plan.defaultSource,
        payments: [...plan.payments, payment],
        status: 'active',
      );
    notifyListeners();
    await _persist();
  }

  Future<void> deleteInstallmentPlan(String planId) async {
    installmentPlans = installmentPlans
        .where((plan) => plan.id != planId)
        .toList();
    notifyListeners();
    await _persist();
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    savingsGoals = [...savingsGoals, goal];
    notifyListeners();
    await _persist();
  }

  Future<void> payInstallment({
    required String planId,
    required String paymentId,
    required String source,
  }) async {
    final planIndex = installmentPlans.indexWhere((plan) => plan.id == planId);
    if (planIndex < 0) return;
    final plan = installmentPlans[planIndex];
    final paymentIndex = plan.payments.indexWhere(
      (item) => item.id == paymentId,
    );
    if (paymentIndex < 0 || plan.payments[paymentIndex].paid) return;
    final payment = plan.payments[paymentIndex];
    _requireSufficientBalance(source, payment.amount);
    final expense = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '${plan.name} - Bayar ${payment.sequence}',
      category: 'Cicilan',
      kind: 'bills',
      source: source,
      amount: payment.amount,
      date: DateTime.now(),
    );
    items.insert(0, expense);
    _changeBalance(source, -payment.amount);
    final updatedPayment = payment.copyWith(
      paid: true,
      paidDate: DateTime.now(),
      actualSource: source,
      expenseId: expense.id,
    );
    final payments = [...plan.payments]..[paymentIndex] = updatedPayment;
    installmentPlans = [...installmentPlans]
      ..[planIndex] = InstallmentPlan(
        id: plan.id,
        name: plan.name,
        provider: plan.provider,
        defaultSource: plan.defaultSource,
        payments: payments,
        status: payments.every((item) => item.paid) ? 'completed' : plan.status,
      );
    notifyListeners();
    await _persist();
  }

  Future<void> addSavingsEntry({
    required String goalId,
    required SavingsEntry entry,
  }) async {
    final index = savingsGoals.indexWhere((goal) => goal.id == goalId);
    if (index < 0) return;
    if (entry.type == 'deposit') {
      _requireSufficientBalance(entry.source, entry.amount);
    }
    _changeBalance(
      entry.source,
      entry.type == 'deposit' ? -entry.amount : entry.amount,
    );
    final goal = savingsGoals[index];
    final entries = [...goal.entries, entry];
    savingsGoals = [...savingsGoals]
      ..[index] = SavingsGoal(
        id: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        targetDate: goal.targetDate,
        contributors: goal.contributors,
        entries: entries,
        status:
            goal.targetAmount != null &&
                goal.balance +
                        (entry.type == 'deposit'
                            ? entry.amount
                            : -entry.amount) >=
                    goal.targetAmount!
            ? 'completed'
            : goal.status,
      );
    notifyListeners();
    await _persist();
  }

  void _changeBalance(String source, double amount) {
    switch (source) {
      case 'cash':
        cash += amount;
      case 'ewallet':
        ewallet += amount;
      default:
        bank += amount;
    }
  }

  String _accountName(String source) => source == 'cash'
      ? 'Cash'
      : source == 'ewallet'
      ? 'E-Wallet'
      : 'Bank';

  void _requireSufficientBalance(String source, double amount) {
    final available = balanceFor(source);
    if (amount > available) {
      throw InsufficientBalanceException(
        source: source,
        available: available,
        required: amount,
      );
    }
  }

  void _markLinkedPaymentUnpaid(String expenseId) {
    for (var planIndex = 0; planIndex < installmentPlans.length; planIndex++) {
      final plan = installmentPlans[planIndex];
      final paymentIndex = plan.payments.indexWhere(
        (payment) => payment.expenseId == expenseId,
      );
      if (paymentIndex < 0) continue;
      final payments = [...plan.payments]
        ..[paymentIndex] = plan.payments[paymentIndex].copyWith(
          paid: false,
          clearPaymentDetails: true,
        );
      installmentPlans = [...installmentPlans]
        ..[planIndex] = InstallmentPlan(
          id: plan.id,
          name: plan.name,
          provider: plan.provider,
          defaultSource: plan.defaultSource,
          payments: payments,
          status: 'active',
        );
      return;
    }
  }

  Map<String, dynamic> createBackup() => {
    'app': 'Dompetku',
    'version': 2,
    'created_at': DateTime.now().toIso8601String(),
    'data': {
      'budget': _legacyBudget,
      'monthly_budgets': monthlyBudgets,
      'cash': cash,
      'ewallet': ewallet,
      'bank': bank,
      'user_name': userName,
      'onboarded': onboarded,
      'items': items.map((item) => item.toJson()).toList(),
      'installment_plans': installmentPlans
          .map((plan) => plan.toJson())
          .toList(),
      'savings_goals': savingsGoals.map((goal) => goal.toJson()).toList(),
    },
  };

  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    final raw = backup['data'];
    if (backup['app'] != 'Dompetku' || raw is! Map || raw['items'] is! List) {
      throw const FormatException('Backup tidak valid.');
    }
    final data = Map<String, dynamic>.from(raw);
    double number(String key) => (data[key] as num?)?.toDouble() ?? 0;
    _legacyBudget = number('budget');
    final rawBudgets = data['monthly_budgets'];
    monthlyBudgets = rawBudgets is Map
        ? rawBudgets.map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
          )
        : {};
    cash = number('cash');
    ewallet = number('ewallet');
    bank = number('bank');
    userName = (data['user_name'] as String?)?.trim().isNotEmpty == true
        ? data['user_name'] as String
        : 'Teman Finansial';
    onboarded = data['onboarded'] as bool? ?? true;
    items =
        (data['items'] as List)
            .map(
              (item) =>
                  Expense.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    installmentPlans = _decodeListFromBackup(
      data['installment_plans'],
      (item) => InstallmentPlan.fromJson(item),
    );
    savingsGoals = _decodeListFromBackup(
      data['savings_goals'],
      (item) => SavingsGoal.fromJson(item),
    );
    notifyListeners();
    await _persist();
  }

  List<T> _decodeListFromBackup<T>(
    dynamic value,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (value is! List) return [];
    return value
        .map((item) => parse(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}

class InsufficientBalanceException implements Exception {
  const InsufficientBalanceException({
    required this.source,
    required this.available,
    required this.required,
  });
  final String source;
  final double available;
  final double required;
}
