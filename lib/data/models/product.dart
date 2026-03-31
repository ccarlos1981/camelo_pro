/// Modelo de dados de um Produto.
///
/// Preços são armazenados em centavos (BIGINT) para evitar
/// problemas de precisão com ponto flutuante.
/// Ex: R$ 5,50 → 550
class Product {
  final String id;
  final String companyId;
  final String? barcode;
  final String name;
  final String? description;
  final String? photoUrl;
  final int buyPrice;        // Custo de compra (centavos)
  final int grossCostMarkup; // Markup de custo bruto (centavos)
  final int pricePix;        // Preço Pix/Dinheiro (centavos)
  final int priceCard;       // Preço Cartão (centavos)
  final bool isCombo;
  final int stockQuantity;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.companyId,
    this.barcode,
    required this.name,
    this.description,
    this.photoUrl,
    this.buyPrice = 0,
    this.grossCostMarkup = 0,
    this.pricePix = 0,
    this.priceCard = 0,
    this.isCombo = false,
    this.stockQuantity = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Custo total real (compra + custos ocultos), em centavos.
  int get totalCost => buyPrice + grossCostMarkup;

  /// Lucro estimado na venda Pix, em centavos.
  int get profitPix => pricePix - totalCost;

  /// Lucro estimado na venda Cartão, em centavos.
  int get profitCard => priceCard - totalCost;

  /// Formata centavos para Real brasileiro. Ex: 550 → "5,50"
  static String centsToReal(int cents) {
    final reais = cents ~/ 100;
    final centavos = (cents % 100).toString().padLeft(2, '0');
    return '$reais,$centavos';
  }

  /// Converte string "5,50" ou "5.50" para centavos (550).
  static int realToCents(String value) {
    if (value.isEmpty) return 0;
    final normalized = value.replaceAll('.', '').replaceAll(',', '.');
    final parsed = double.tryParse(normalized) ?? 0;
    return (parsed * 100).round();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      barcode: json['barcode'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      buyPrice: (json['buy_price'] as num?)?.toInt() ?? 0,
      grossCostMarkup: (json['gross_cost_markup'] as num?)?.toInt() ?? 0,
      pricePix: (json['price_pix_cash'] as num?)?.toInt() ?? 0,
      priceCard: (json['price_card'] as num?)?.toInt() ?? 0,
      isCombo: json['is_combo'] as bool? ?? false,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'company_id': companyId,
      if (barcode != null) 'barcode': barcode,
      'name': name,
      if (description != null) 'description': description,
      if (photoUrl != null) 'photo_url': photoUrl,
      'buy_price': buyPrice,
      'gross_cost_markup': grossCostMarkup,
      'price_pix_cash': pricePix,
      'price_card': priceCard,
      'is_combo': isCombo,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
    };
  }

  Product copyWith({
    String? barcode,
    String? name,
    String? description,
    String? photoUrl,
    int? buyPrice,
    int? grossCostMarkup,
    int? pricePix,
    int? priceCard,
    bool? isCombo,
    int? stockQuantity,
    bool? isActive,
  }) {
    return Product(
      id: id,
      companyId: companyId,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      buyPrice: buyPrice ?? this.buyPrice,
      grossCostMarkup: grossCostMarkup ?? this.grossCostMarkup,
      pricePix: pricePix ?? this.pricePix,
      priceCard: priceCard ?? this.priceCard,
      isCombo: isCombo ?? this.isCombo,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
    );
  }
}
