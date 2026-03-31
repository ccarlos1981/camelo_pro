import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/debt.dart';

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  return DebtsRepository(Supabase.instance.client);
});

class DebtsRepository {
  final SupabaseClient _client;
  DebtsRepository(this._client);

  Future<List<Debt>> fetchDebts(String companyId) async {
    final response = await _client
        .from('debts')
        .select('*, products(name)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Debt.fromJson(json)).toList();
  }

  Future<Debt> createDebt(Debt debt) async {
    final response = await _client
        .from('debts')
        .insert(debt.toJson())
        .select('*, products(name)')
        .single();

    final createdDebt = Debt.fromJson(response);

    // Ajuste de Estoque para Mútua
    if (createdDebt.category == DebtCategory.neighbor &&
        createdDebt.productId != null &&
        createdDebt.quantity > 0) {
      // Se eu emprestei, meu estoque DIMINUI. Se eu peguei emprestado, AUMENTA.
      final isReceivable = (createdDebt.type == DebtType.receivable);
      
      try {
        if (isReceivable) {
          await _client.rpc('decrement_stock', params: {
            'p_product_id': createdDebt.productId,
            'p_quantity': createdDebt.quantity,
          });
        } else {
          // Peguei emprestado (payable): Entra no meu estoque
          await _client.rpc('increment_stock', params: {
            'p_product_id': createdDebt.productId,
            'p_quantity': createdDebt.quantity,
          });
        }
      } catch (e) {
        // Fallback manual caso a RPC falhe ou não exista
        await _updateStockFallback(
          productId: createdDebt.productId!,
          quantity: createdDebt.quantity,
          decrement: isReceivable,
        );
      }
    }

    return createdDebt;
  }

  Future<Debt> settleDebt(Debt debt, {SettlementType? settlementType}) async {
    final response = await _client
        .from('debts')
        .update({
          'status': 'settled',
          'settled_at': DateTime.now().toIso8601String(),
          if (settlementType != null)
            'settlement_type': settlementType == SettlementType.productReturn 
                ? 'product_return' 
                : 'cash_payment',
        })
        .eq('id', debt.id!)
        .select('*, products(name)')
        .single();

    final settledDebt = Debt.fromJson(response);

    // Se Mútua e liquidada APENAS mediante devolução de produto: reverter o estoque
    if (settledDebt.category == DebtCategory.neighbor &&
        settledDebt.productId != null &&
        settlementType == SettlementType.productReturn) {
      
      // Se eu tinha emprestado (receivable), estou recebendo de volta -> AUMENTA estoque
      // Se eu tinha pegado (payable), estou devolvendo -> DIMINUI estoque
      final wasReceivable = (settledDebt.type == DebtType.receivable);

      try {
        if (wasReceivable) {
          await _client.rpc('increment_stock', params: {
            'p_product_id': settledDebt.productId,
            'p_quantity': settledDebt.quantity,
          });
        } else {
          await _client.rpc('decrement_stock', params: {
            'p_product_id': settledDebt.productId,
            'p_quantity': settledDebt.quantity,
          });
        }
      } catch (e) {
        // Fallback manual
        await _updateStockFallback(
          productId: settledDebt.productId!,
          quantity: settledDebt.quantity,
          decrement: !wasReceivable, // Se era receivable, eu reverto INCREMENTANDO (decrement = false)
        );
      }
    }

    return settledDebt;
  }

  Future<void> _updateStockFallback({
    required String productId,
    required int quantity,
    required bool decrement,
  }) async {
    // 1. Busca estoque atual
    final pData = await _client
        .from('products')
        .select('stock_quantity')
        .eq('id', productId)
        .single();
    
    final currentStock = pData['stock_quantity'] as int? ?? 0;
    
    // 2. Calcula novo
    int newStock = decrement ? currentStock - quantity : currentStock + quantity;
    if (newStock < 0) newStock = 0;

    // 3. Atualiza
    await _client.from('products').update({'stock_quantity': newStock}).eq('id', productId);
  }

  Future<void> deleteDebt(String id) async {
    // Nota: Exclusão de dívida pendente ou liquidada teoricamente não desfaz o estoque, 
    // a menos que desejemos implementar essa reversão (como excluir um estorno). Por simplicidade:
    await _client.from('debts').delete().eq('id', id);
  }
}
