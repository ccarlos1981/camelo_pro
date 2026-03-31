import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/product.dart';
import '../../data/repositories/products_repository.dart';

/// Provider do repositório de produtos.
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(Supabase.instance.client);
});

/// Provider reativo da lista de produtos.
final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(() {
  return ProductsNotifier();
});

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  ProductsRepository get _repo => ref.read(productsRepositoryProvider);

  @override
  Future<List<Product>> build() async {
    return _repo.fetchProducts();
  }

  /// Adiciona um produto e atualiza a lista local instantaneamente.
  Future<Product> addProduct(Product product, {File? photo}) async {
    final created = await _repo.createProduct(product);

    // Upload de foto se fornecida
    Product finalProduct = created;
    if (photo != null) {
      final url = await _repo.uploadPhoto(created.id, photo);
      finalProduct = created.copyWith(photoUrl: url);
      await _repo.updateProduct(finalProduct);
    }

    // Atualiza cache local
    final current = state.value ?? [];
    state = AsyncData([finalProduct, ...current]);

    return finalProduct;
  }

  /// Atualiza um produto existente.
  Future<void> updateProduct(Product product) async {
    final updated = await _repo.updateProduct(product);
    final current = state.value ?? [];
    state = AsyncData(
      current.map((p) => p.id == updated.id ? updated : p).toList(),
    );
  }

  /// Toggle ativo/inativo.
  Future<void> toggleActive(String productId) async {
    final current = state.value ?? [];
    final product = current.firstWhere((p) => p.id == productId);
    final newStatus = !product.isActive;

    await _repo.toggleActive(productId, newStatus);
    state = AsyncData(
      current
          .map((p) => p.id == productId ? p.copyWith(isActive: newStatus) : p)
          .toList(),
    );
  }

  /// Exclui um produto.
  Future<void> deleteProduct(String productId) async {
    await _repo.deleteProduct(productId);
    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != productId).toList());
  }

  /// Busca por barcode.
  Future<Product?> findByBarcode(String barcode) async {
    return _repo.findByBarcode(barcode);
  }

  /// Recarrega a lista do servidor.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _repo.fetchProducts());
  }
}
