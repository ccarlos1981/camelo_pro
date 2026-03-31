/// Modelo de venda registrada no PDV.
class Sale {
  final String id;
  final String companyId;
  final String sellerId;
  final String? customerId;
  final String paymentMethod; // 'pix', 'card', 'cash'
  final int totalAmount; // centavos
  final String status; // 'completed', 'cancelled'
  final String? notes;
  final DateTime? createdAt;

  // Dados de join
  final String? sellerName;
  final String? customerName;
  final List<SaleItem>? items;

  const Sale({
    required this.id,
    required this.companyId,
    required this.sellerId,
    this.customerId,
    this.paymentMethod = 'pix',
    this.totalAmount = 0,
    this.status = 'completed',
    this.notes,
    this.createdAt,
    this.sellerName,
    this.customerName,
    this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    final seller = json['seller'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;

    // Parseia itens se vieram no join (alias 'items' ou 'sale_items')
    final rawItems = (json['items'] as List?) ?? (json['sale_items'] as List?);
    final parsedItems = rawItems?.map((i) {
      if (i is Map<String, dynamic>) {
        return SaleItem.fromJson({
          ...i,
          'id': i['id'] ?? '',
          'sale_id': i['sale_id'] ?? json['id'] ?? '',
          'product_id': i['product_id'] ?? '',
        });
      }
      return null;
    }).whereType<SaleItem>().toList();

    return Sale(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      sellerId: json['seller_id'] as String,
      customerId: json['customer_id'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'pix',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'completed',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      sellerName: seller?['name'] as String?,
      customerName: customer?['name'] as String?,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'company_id': companyId,
    'seller_id': sellerId,
    'customer_id': customerId,
    'payment_method': paymentMethod,
    'total_amount': totalAmount,
    'notes': notes,
  };

  String get paymentLabel {
    switch (paymentMethod) {
      case 'pix':
        return 'Pix';
      case 'card':
        return 'Cartão';
      case 'cash':
        return 'Dinheiro';
      default:
        return paymentMethod;
    }
  }
}

/// Item individual de uma venda.
class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final int quantity;
  final int unitPrice; // centavos
  final int unitCost; // custo na hora da venda (centavos)

  // Join data
  final String? productName;
  final String? productPhotoUrl;
  final int? productBuyPrice;
  final int? productMarkup;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    this.quantity = 1,
    this.unitPrice = 0,
    this.unitCost = 0,
    this.productName,
    this.productPhotoUrl,
    this.productBuyPrice,
    this.productMarkup,
  });

  int get subtotal => quantity * unitPrice;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return SaleItem(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toInt() ?? 0,
      unitCost: (json['unit_cost'] as num?)?.toInt() ?? 0,
      productName: product?['name'] as String?,
      productPhotoUrl: product?['photo_url'] as String?,
      productBuyPrice: (product?['buy_price'] as num?)?.toInt(),
      productMarkup: (product?['gross_cost_markup'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'sale_id': saleId,
    'product_id': productId,
    'quantity': quantity,
    'unit_price': unitPrice,
    'unit_cost': unitCost,
  };
}
