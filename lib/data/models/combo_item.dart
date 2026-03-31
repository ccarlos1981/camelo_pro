/// Modelo de dados de um item de combo.
///
/// Cada combo_item vincula um produto-item a um produto-combo,
/// com uma quantidade definida.
class ComboItem {
  final String id;
  final String comboProductId;
  final String itemProductId;
  final int quantity;
  final DateTime? createdAt;

  // Campos extras para exibição (não persistidos)
  final String? itemName;
  final String? itemPhotoUrl;

  const ComboItem({
    required this.id,
    required this.comboProductId,
    required this.itemProductId,
    this.quantity = 1,
    this.createdAt,
    this.itemName,
    this.itemPhotoUrl,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    // Suporta join com products (item_product:products(...))
    final itemProduct = json['item_product'] as Map<String, dynamic>?;

    return ComboItem(
      id: json['id'] as String,
      comboProductId: json['combo_product_id'] as String,
      itemProductId: json['item_product_id'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      itemName: itemProduct?['name'] as String?,
      itemPhotoUrl: itemProduct?['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'combo_product_id': comboProductId,
      'item_product_id': itemProductId,
      'quantity': quantity,
    };
  }

  ComboItem copyWith({int? quantity}) {
    return ComboItem(
      id: id,
      comboProductId: comboProductId,
      itemProductId: itemProductId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
      itemName: itemName,
      itemPhotoUrl: itemPhotoUrl,
    );
  }
}
