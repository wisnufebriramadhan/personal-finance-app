class SavingsEntry {
  const SavingsEntry({
    required this.id,
    required this.type,
    required this.contributor,
    required this.amount,
    required this.date,
    required this.source,
    this.note = '',
  });

  final String id;
  final String type;
  final String contributor;
  final double amount;
  final DateTime date;
  final String source;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'contributor': contributor,
    'amount': amount,
    'date': date.toIso8601String(),
    'source': source,
    'note': note,
  };

  factory SavingsEntry.fromJson(Map<String, dynamic> json) => SavingsEntry(
    id: json['id'] as String,
    type: json['type'] as String,
    contributor: json['contributor'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    source: json['source'] as String,
    note: json['note'] as String? ?? '',
  );
}

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.entries,
    this.targetAmount,
    this.targetDate,
    this.contributors = const [],
    this.status = 'active',
  });

  final String id;
  final String name;
  final double? targetAmount;
  final DateTime? targetDate;
  final List<String> contributors;
  final List<SavingsEntry> entries;
  final String status;

  double get balance => entries.fold(
    0,
    (sum, entry) =>
        sum + (entry.type == 'deposit' ? entry.amount : -entry.amount),
  );
  double get progress => targetAmount == null || targetAmount == 0
      ? 0
      : (balance / targetAmount!).clamp(0, 1);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'target_amount': targetAmount,
    'target_date': targetDate?.toIso8601String(),
    'contributors': contributors,
    'status': status,
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
    id: json['id'] as String,
    name: json['name'] as String,
    targetAmount: (json['target_amount'] as num?)?.toDouble(),
    targetDate: json['target_date'] == null
        ? null
        : DateTime.parse(json['target_date'] as String),
    contributors: (json['contributors'] as List?)?.cast<String>() ?? const [],
    status: json['status'] as String? ?? 'active',
    entries: (json['entries'] as List)
        .map(
          (entry) =>
              SavingsEntry.fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .toList(),
  );
}
