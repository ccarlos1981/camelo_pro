import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale.dart';
import '../models/product.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(Supabase.instance.client);
});

class SalesRepository {
  final SupabaseClient _client;
  SalesRepository(this._client);

  /// Registra uma venda com itens.
  Future<Sale> createSale({
    required String companyId,
    required String sellerId,
    required String paymentMethod,
    required int totalAmount,
    required List<CartItem> items,
    String? customerId,
    String? notes,
  }) async {
    // 1. Cria a venda
    final saleData = await _client
        .from('sales')
        .insert({
          'company_id': companyId,
          'seller_id': sellerId,
          'customer_id': customerId,
          'payment_method': paymentMethod,
          'total_amount': totalAmount,
          'notes': notes,
        })
        .select()
        .single();

    final saleId = saleData['id'] as String;

    // 2. Insere os itens
    final itemsData = items.map((item) => {
      'sale_id': saleId,
      'product_id': item.product.id,
      'quantity': item.quantity,
      'unit_price': paymentMethod == 'card' ? item.product.priceCard : item.product.pricePix,
      'unit_cost': item.product.totalCost,
    }).toList();

    await _client.from('sale_items').insert(itemsData);

    // 3. Atualiza estoque
    for (final item in items) {
      await _client.rpc('decrement_stock', params: {
        'p_product_id': item.product.id,
        'p_quantity': item.quantity,
      }).catchError((_) async {
        // Fallback: update direto
        await _client
            .from('products')
            .update({
              'stock_quantity': item.product.stockQuantity - item.quantity,
            })
            .eq('id', item.product.id);
      });
    }

    return Sale.fromJson(saleData);
  }

  /// Busca vendas de hoje.
  Future<List<Sale>> fetchTodaySales(String companyId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

    final data = await _client
        .from('sales')
        .select('*, seller:profiles!seller_id(name), customer:customers(name)')
        .eq('company_id', companyId)
        .gte('created_at', startOfDay)
        .order('created_at', ascending: false);

    return (data as List).map((e) => Sale.fromJson(e)).toList();
  }

  /// Busca vendas (e seus itens) em um intervalo de datas para calcular DRE
  Future<List<Sale>> fetchSalesBetween(String companyId, DateTime start, DateTime end) async {
    final startIso = start.toUtc().toIso8601String();
    final endIso = end.toUtc().toIso8601String();

    final response = await _client
        .from('sales')
        .select('*, items:sale_items(id, sale_id, product_id, quantity, unit_price, unit_cost)')
        .eq('company_id', companyId)
        .eq('status', 'completed')
        .gte('created_at', startIso)
        .lte('created_at', endIso)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Sale.fromJson(e)).toList();
  }

  /// Busca resumo de vendas de hoje (total + contagem).
  Future<Map<String, dynamic>> fetchTodaySummary(String companyId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

    final data = await _client
        .from('sales')
        .select('total_amount')
        .eq('company_id', companyId)
        .eq('status', 'completed')
        .gte('created_at', startOfDay);

    final sales = data as List;
    final totalAmount = sales.fold<int>(
      0,
      (sum, sale) => sum + ((sale['total_amount'] as num?)?.toInt() ?? 0),
    );

    return {
      'count': sales.length,
      'total': totalAmount,
    };
  }
}

/// Item do carrinho (não persistido, usado na tela de PDV).
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get subtotal => quantity * product.pricePix;
  int subtotalForMethod(String method) {
    return quantity * (method == 'card' ? product.priceCard : product.pricePix);
  }
}
