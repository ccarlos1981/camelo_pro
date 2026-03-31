enum DebtType { receivable, payable }
enum DebtCategory { customer, neighbor }
enum SettlementType { productReturn, cashPayment }

class Debt {
  final String? id;
  final String companyId;
  final String sellerId;
  final DebtType type;
  final DebtCategory category;
  final String personName;
  final int amount; // Em centavos para Fiado ou quando devolvido em R$
  final String? description;
  final String status; // 'pending' ou 'settled'
  final DateTime? settledAt;
  final DateTime? createdAt;
  
  // Mútua (Produtos)
  final String? productId;
  final int quantity;
  final SettlementType? settlementType;

  // Campo helper
  final String? productName; // Para exibir na UI sem precisar de Join complexo no repository (se o Join for feito)

  bool get isCustomer => category == DebtCategory.customer;
  bool get isNeighbor => category == DebtCategory.neighbor;

  Debt({
    this.id,
    required this.companyId,
    required this.sellerId,
    required this.type,
    required this.category,
    required this.personName,
    this.amount = 0,
    this.description,
    this.status = 'pending',
    this.settledAt,
    this.createdAt,
    this.productId,
    this.quantity = 0,
    this.settlementType,
    this.productName,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String?,
      companyId: json['company_id'] as String,
      sellerId: json['seller_id'] as String,
      type: json['type'] == 'receivable' ? DebtType.receivable : DebtType.payable,
      category: json['category'] == 'customer' ? DebtCategory.customer : DebtCategory.neighbor,
      personName: json['person_name'] as String,
      amount: json['amount'] as int? ?? 0,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      settledAt: json['settled_at'] != null ? DateTime.parse(json['settled_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      productId: json['product_id'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      settlementType: json['settlement_type'] == 'product_return' 
          ? SettlementType.productReturn 
          : (json['settlement_type'] == 'cash_payment' ? SettlementType.cashPayment : null),
      productName: json['products']?['name'] as String?, // Se feito um Join
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'company_id': companyId,
      'seller_id': sellerId,
      'type': type == DebtType.receivable ? 'receivable' : 'payable',
      'category': category == DebtCategory.customer ? 'customer' : 'neighbor',
      'person_name': personName,
      'amount': amount,
      'description': description,
      'status': status,
      if (settledAt != null) 'settled_at': settledAt!.toIso8601String(),
      'product_id': productId,
      'quantity': quantity,
      if (settlementType != null) 
        'settlement_type': settlementType == SettlementType.productReturn ? 'product_return' : 'cash_payment',
    };
  }

  Debt copyWith({
    String? id,
    String? companyId,
    String? sellerId,
    DebtType? type,
    DebtCategory? category,
    String? personName,
    int? amount,
    String? description,
    String? status,
    DateTime? settledAt,
    DateTime? createdAt,
    String? productId,
    int? quantity,
    SettlementType? settlementType,
    String? productName,
  }) {
    return Debt(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      sellerId: sellerId ?? this.sellerId,
      type: type ?? this.type,
      category: category ?? this.category,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt ?? this.createdAt,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      settlementType: settlementType ?? this.settlementType,
      productName: productName ?? this.productName,
    );
  }
}
