class InstallmentPayment {
  const InstallmentPayment({
    required this.id,
    required this.sequence,
    required this.dueDate,
    required this.amount,
    this.paid = false,
    this.paidDate,
    this.actualSource,
    this.expenseId,
  });

  final String id;
  final int sequence;
  final DateTime dueDate;
  final double amount;
  final bool paid;
  final DateTime? paidDate;
  final String? actualSource;
  final String? expenseId;

  InstallmentPayment copyWith({
    bool? paid,
    DateTime? paidDate,
    String? actualSource,
    String? expenseId,
    bool clearPaymentDetails = false,
  }) => InstallmentPayment(
    id: id,
    sequence: sequence,
    dueDate: dueDate,
    amount: amount,
    paid: paid ?? this.paid,
    paidDate: clearPaymentDetails ? null : paidDate ?? this.paidDate,
    actualSource: clearPaymentDetails
        ? null
        : actualSource ?? this.actualSource,
    expenseId: clearPaymentDetails ? null : expenseId ?? this.expenseId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sequence': sequence,
    'due_date': dueDate.toIso8601String(),
    'amount': amount,
    'paid': paid,
    'paid_date': paidDate?.toIso8601String(),
    'actual_source': actualSource,
    'expense_id': expenseId,
  };

  factory InstallmentPayment.fromJson(Map<String, dynamic> json) =>
      InstallmentPayment(
        id: json['id'] as String,
        sequence: (json['sequence'] as num).toInt(),
        dueDate: DateTime.parse(json['due_date'] as String),
        amount: (json['amount'] as num).toDouble(),
        paid: json['paid'] as bool? ?? false,
        paidDate: json['paid_date'] == null
            ? null
            : DateTime.parse(json['paid_date'] as String),
        actualSource: json['actual_source'] as String?,
        expenseId: json['expense_id'] as String?,
      );
}

class InstallmentPlan {
  const InstallmentPlan({
    required this.id,
    required this.name,
    required this.provider,
    required this.defaultSource,
    required this.payments,
    this.status = 'active',
  });

  final String id;
  final String name;
  final String provider;
  final String defaultSource;
  final List<InstallmentPayment> payments;
  final String status;

  int get paidCount => payments.where((payment) => payment.paid).length;
  double get totalAmount =>
      payments.fold(0, (sum, payment) => sum + payment.amount);
  double get paidAmount => payments
      .where((payment) => payment.paid)
      .fold(0, (sum, payment) => sum + payment.amount);
  double get remainingAmount => payments
      .where((payment) => !payment.paid)
      .fold(0, (sum, payment) => sum + payment.amount);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'provider': provider,
    'default_source': defaultSource,
    'status': status,
    'payments': payments.map((payment) => payment.toJson()).toList(),
  };

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) =>
      InstallmentPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        provider: json['provider'] as String? ?? '',
        defaultSource: json['default_source'] as String? ?? 'bank',
        status: json['status'] as String? ?? 'active',
        payments: (json['payments'] as List)
            .map(
              (payment) => InstallmentPayment.fromJson(
                Map<String, dynamic>.from(payment as Map),
              ),
            )
            .toList(),
      );
}
