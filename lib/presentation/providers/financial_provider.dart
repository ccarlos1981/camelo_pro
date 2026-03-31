import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense.dart';
import '../../data/models/sale.dart';
import '../../data/repositories/financial_repository.dart';
import 'user_profile_provider.dart';

class FinancialState {
  final bool isLoading;
  final String? error;
  
  // Datas filtro
  final DateTime startDate;
  final DateTime endDate;

  // Raw data
  final List<Sale> sales;
  final List<Expense> expenses;

  // Calculados
  final int totalRevenue;   // Receita Bruta (Soma das vendas)
  final int totalCostCurrent; // CMV (Custo Baseado no Produto Hoje)
  final int totalCostHistorical; // CMV (Custo Congelado na Venda)
  final int totalExpenses; // Soma das Despesas

  int get grossProfitLight => totalRevenue - totalCostCurrent;
  int get grossProfitMedium => totalRevenue - totalCostHistorical;
  int get netProfitFull => grossProfitMedium - totalExpenses;

  const FinancialState({
    this.isLoading = false,
    this.error,
    required this.startDate,
    required this.endDate,
    this.sales = const [],
    this.expenses = const [],
    this.totalRevenue = 0,
    this.totalCostCurrent = 0,
    this.totalCostHistorical = 0,
    this.totalExpenses = 0,
  });

  FinancialState copyWith({
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    List<Sale>? sales,
    List<Expense>? expenses,
    int? totalRevenue,
    int? totalCostCurrent,
    int? totalCostHistorical,
    int? totalExpenses,
  }) {
    return FinancialState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sales: sales ?? this.sales,
      expenses: expenses ?? this.expenses,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCostCurrent: totalCostCurrent ?? this.totalCostCurrent,
      totalCostHistorical: totalCostHistorical ?? this.totalCostHistorical,
      totalExpenses: totalExpenses ?? this.totalExpenses,
    );
  }
}

class FinancialNotifier extends Notifier<FinancialState> {
  @override
  FinancialState build() {
    return FinancialState(
      // Padrão: Últimos 30 dias
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
  }

  /// Altera o período e recarrega os dados
  Future<void> setDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(startDate: start, endDate: end);
    await loadData();
  }

  /// Busca vendas e despesas do repositório
  Future<void> loadData() async {
    final companyId = ref.read(userProfileProvider).value?.companyId;
    if (companyId == null || companyId.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(financialRepositoryProvider);
      
      final sales = await repository.fetchSalesWithItems(
        companyId,
        state.startDate,
        DateTime(state.endDate.year, state.endDate.month, state.endDate.day, 23, 59, 59),
      );

      final expenses = await repository.fetchExpenses(
        companyId,
        state.startDate,
        DateTime(state.endDate.year, state.endDate.month, state.endDate.day, 23, 59, 59),
      );

      _calculateMetrics(sales, expenses);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao carregar balanço: $e');
    }
  }

  void _calculateMetrics(List<Sale> sales, List<Expense> expenses) {
    int revenue = 0;
    int currentCost = 0;
    int historicalCost = 0;
    int expensesTotal = 0;

    for (final sale in sales) {
      if (sale.status != 'completed') continue;
      
      revenue += sale.totalAmount;
      
      final items = sale.items ?? [];
      for (final item in items) {
        // Custo atual do produto (mock de DRE Light)
        final int buyPrice = item.productBuyPrice ?? 0;
        final int markup = item.productMarkup ?? 0;
        
        currentCost += (buyPrice + markup) * item.quantity;
        
        // Custo histórico (DRE Medium/Full)
        historicalCost += item.unitCost * item.quantity;
      }
    }

    for (final exp in expenses) {
      expensesTotal += exp.amount;
    }

    state = state.copyWith(
      isLoading: false,
      sales: sales,
      expenses: expenses,
      totalRevenue: revenue,
      totalCostCurrent: currentCost,
      totalCostHistorical: historicalCost,
      totalExpenses: expensesTotal,
    );
  }

  Future<void> addExpense(String description, int amount, DateTime date) async {
    final companyId = ref.read(userProfileProvider).value?.companyId;
    if (companyId == null) return;
    
    try {
      final newExpense = Expense(
        id: '', // Supabase gera
        companyId: companyId,
        description: description,
        amount: amount,
        expenseDate: date,
      );

      final repository = ref.read(financialRepositoryProvider);
      final created = await repository.createExpense(newExpense);
      
      final updatedExpenses = [created, ...state.expenses]..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      _calculateMetrics(state.sales, updatedExpenses);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao adicionar despesa: $e');
    }
  }

  Future<void> removeExpense(String id) async {
    try {
      final repository = ref.read(financialRepositoryProvider);
      await repository.deleteExpense(id);
      
      final updatedExpenses = state.expenses.where((e) => e.id != id).toList();
      _calculateMetrics(state.sales, updatedExpenses);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao deletar despesa: $e');
    }
  }
}

final financialProvider = NotifierProvider<FinancialNotifier, FinancialState>(() {
  return FinancialNotifier();
});
