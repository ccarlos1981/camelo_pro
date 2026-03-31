import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

/// Repositório de produtos — comunicação direta com Supabase.
class ProductsRepository {
  final SupabaseClient _client;

  ProductsRepository(this._client);

  /// Retorna o company_id do usuário logado.
  Future<String> _getCompanyId() async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('profiles')
        .select('company_id')
        .eq('id', userId)
        .single();
    return row['company_id'] as String;
  }

  /// Lista todos os produtos da empresa do usuário logado.
  Future<List<Product>> fetchProducts() async {
    final data = await _client
        .from('products')
        .select()
        .order('created_at', ascending: false);

    return (data as List).map((json) => Product.fromJson(json)).toList();
  }

  /// Cria um novo produto.
  Future<Product> createProduct(Product product) async {
    final companyId = await _getCompanyId();
    final json = product.toInsertJson();
    json['company_id'] = companyId;

    final row = await _client.from('products').insert(json).select().single();
    return Product.fromJson(row);
  }

  /// Atualiza um produto existente.
  Future<Product> updateProduct(Product product) async {
    final row = await _client
        .from('products')
        .update(product.toInsertJson())
        .eq('id', product.id)
        .select()
        .single();
    return Product.fromJson(row);
  }

  /// Alterna o status ativo/inativo.
  Future<void> toggleActive(String productId, bool isActive) async {
    await _client
        .from('products')
        .update({'is_active': isActive})
        .eq('id', productId);
  }

  /// Exclui um produto.
  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
  }

  /// Faz upload de foto e retorna a URL pública.
  Future<String> uploadPhoto(String productId, File file) async {
    final companyId = await _getCompanyId();
    final ext = file.path.split('.').last;
    final path = '$companyId/$productId.$ext';

    await _client.storage.from('product-photos').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _client.storage.from('product-photos').getPublicUrl(path);
  }

  /// Busca produto por barcode dentro da empresa.
  Future<Product?> findByBarcode(String barcode) async {
    final data = await _client
        .from('products')
        .select()
        .eq('barcode', barcode)
        .maybeSingle();

    if (data == null) return null;
    return Product.fromJson(data);
  }

  // ── Combo Items ──────────────────────────────────────────

  /// Lista itens de um combo com dados do produto vinculado.
  Future<List<Map<String, dynamic>>> fetchComboItems(String comboProductId) async {
    final data = await _client
        .from('combo_items')
        .select('*, item_product:products!item_product_id(name, photo_url)')
        .eq('combo_product_id', comboProductId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }

  /// Adiciona um item ao combo.
  Future<void> addComboItem({
    required String comboProductId,
    required String itemProductId,
    int quantity = 1,
  }) async {
    await _client.from('combo_items').upsert({
      'combo_product_id': comboProductId,
      'item_product_id': itemProductId,
      'quantity': quantity,
    }, onConflict: 'combo_product_id,item_product_id');
  }

  /// Remove um item do combo.
  Future<void> removeComboItem(String comboItemId) async {
    await _client.from('combo_items').delete().eq('id', comboItemId);
  }

  /// Atualiza a quantidade de um item no combo.
  Future<void> updateComboItemQuantity(String comboItemId, int quantity) async {
    await _client
        .from('combo_items')
        .update({'quantity': quantity})
        .eq('id', comboItemId);
  }
}

