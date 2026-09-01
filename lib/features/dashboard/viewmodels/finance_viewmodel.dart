import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../expenses/models/expense.dart';

class FinanceViewModel extends ChangeNotifier {
  double budget = 0;
  double cash = 0;
  double ewallet = 0;
  double bank = 0;
  String userName = 'Teman Finansial';
  bool onboarded = false;
  List<Expense> items = [];

  bool get isReady => onboarded || budget > 0;
  double get spent => items.fold(0, (sum, item) => sum + item.amount);
  double get remainingBudget => budget - spent;
  double get budgetProgress => budget == 0 ? 0 : (spent / budget).clamp(0, 1);
  double get totalBalance => cash + ewallet + bank;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    budget = prefs.getDouble('budget') ?? 0;
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
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget', budget);
    await prefs.setDouble('cash', cash);
    await prefs.setDouble('ewallet', ewallet);
    await prefs.setDouble('bank', bank);
    await prefs.setString('user_name', userName);
    await prefs.setBool('onboarded', onboarded);
    await prefs.setString(
      'items',
      jsonEncode(items.map((item) => item.toJson()).toList()),
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
    budget = budgetValue;
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
    budget = value;
    notifyListeners();
    await _persist();
  }

  Future<void> updateBalances({
    required double cashValue,
    required double ewalletValue,
    required double bankValue,
  }) async {
    cash = cashValue;
    ewallet = ewalletValue;
    bank = bankValue;
    notifyListeners();
    await _persist();
  }

  Future<void> addExpense(Expense expense) async {
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

  Map<String, dynamic> createBackup() => {
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
      'items': items.map((item) => item.toJson()).toList(),
    },
  };

  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    final raw = backup['data'];
    if (backup['app'] != 'Dompetku' || raw is! Map || raw['items'] is! List) {
      throw const FormatException('Backup tidak valid.');
    }
    final data = Map<String, dynamic>.from(raw);
    double number(String key) => (data[key] as num?)?.toDouble() ?? 0;
    budget = number('budget');
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
    notifyListeners();
    await _persist();
  }
}
