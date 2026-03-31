import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(Supabase.instance.client);
});

class ExpensesRepository {
  final SupabaseClient _client;

  ExpensesRepository(this._client);

  Future<List<Expense>> getExpenses(String companyId) async {
    final response = await _client
        .from('expenses')
        .select()
        .eq('company_id', companyId)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List).map((data) => Expense.fromJson(data)).toList();
  }
  
  Future<List<Expense>> getExpensesByMonth(String companyId, int year, int month) async {
    // Definimos o primeiro dia do mes
    final startOfMonth = DateTime(year, month, 1).toIso8601String().split('T').first;
    // Pega o ultimo dia do mes
    final endOfMonth = DateTime(year, month + 1, 0).toIso8601String().split('T').first;

    final response = await _client
        .from('expenses')
        .select()
        .eq('company_id', companyId)
        .gte('expense_date', startOfMonth)
        .lte('expense_date', endOfMonth)
        .order('expense_date', ascending: false);

    return (response as List).map((data) => Expense.fromJson(data)).toList();
  }

  Future<List<Expense>> getExpensesBetween(String companyId, DateTime start, DateTime end) async {
    final startStr = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
    final endStr = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";

    final response = await _client
        .from('expenses')
        .select()
        .eq('company_id', companyId)
        .gte('expense_date', startStr)
        .lte('expense_date', endStr)
        .order('expense_date', ascending: false);

    return (response as List).map((data) => Expense.fromJson(data)).toList();
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await _client
        .from('expenses')
        .insert(expense.toInsertJson())
        .select()
        .single();
    return Expense.fromJson(response);
  }

  Future<void> updateExpense(Expense expense) async {
    await _client
        .from('expenses')
        .update({
          'description': expense.description,
          'amount': expense.amount,
          'expense_date': "${expense.expenseDate.year}-${expense.expenseDate.month.toString().padLeft(2, '0')}-${expense.expenseDate.day.toString().padLeft(2, '0')}",
        })
        .eq('id', expense.id)
        .eq('company_id', expense.companyId);
  }

  Future<void> deleteExpense(String id, String companyId) async {
    await _client
        .from('expenses')
        .delete()
        .eq('id', id)
        .eq('company_id', companyId);
  }
}
