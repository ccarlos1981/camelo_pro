import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale.dart';
import '../models/expense.dart';

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  return FinancialRepository(Supabase.instance.client);
});

class FinancialRepository {
  final SupabaseClient _client;
  FinancialRepository(this._client);

  /// Busca vendas concluídas de um período, incluindo seus itens e os produtos relacionados.
  Future<List<Sale>> fetchSalesWithItems(String companyId, DateTime start, DateTime end) async {
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final data = await _client
        .from('sales')
        .select('*, items:sale_items(*, product:products(name, buy_price, gross_cost_markup))')
        .eq('company_id', companyId)
        .eq('status', 'completed')
        .gte('created_at', startStr)
        .lte('created_at', endStr)
        .order('created_at', ascending: false);

    return (data as List).map((e) => Sale.fromJson(e)).toList();
  }

  /// Busca as despesas de um período
  Future<List<Expense>> fetchExpenses(String companyId, DateTime start, DateTime end) async {
    final startStr = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
    final endStr = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";

    final data = await _client
        .from('expenses')
        .select()
        .eq('company_id', companyId)
        .gte('expense_date', startStr)
        .lte('expense_date', endStr)
        .order('expense_date', ascending: false);

    return (data as List).map((e) => Expense.fromJson(e)).toList();
  }

  /// Registra uma nova despesa
  Future<Expense> createExpense(Expense expense) async {
    final data = await _client
        .from('expenses')
        .insert(expense.toInsertJson())
        .select()
        .single();
    
    return Expense.fromJson(data);
  }

  /// Deleta uma despesa
  Future<void> deleteExpense(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }
}
