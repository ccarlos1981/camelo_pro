class Expense {
  final String id;
  final String companyId;
  final String description;
  final int amount; // centavos
  final DateTime expenseDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Expense({
    required this.id,
    required this.companyId,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'company_id': companyId,
      'description': description,
      'amount': amount,
      'expense_date': "${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}",
    };
  }

  Expense copyWith({
    String? description,
    int? amount,
    DateTime? expenseDate,
  }) {
    return Expense(
      id: id,
      companyId: companyId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
