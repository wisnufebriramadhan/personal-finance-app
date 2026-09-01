class Expense {
  const Expense({
    required this.id,
    required this.name,
    required this.category,
    required this.kind,
    required this.source,
    required this.amount,
    required this.date,
  });

  final String id, name, category, kind, source;
  final double amount;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'kind': kind,
    'source': source,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    kind: json['kind'] as String,
    source: json['source'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
  );
}
