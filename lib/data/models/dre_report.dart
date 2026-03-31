class DreReport {
  final int totalRevenue; // Faturamento Bruto (Soma do total_amount de todas as Vendas pagas/fiado? Idealmente fiado tb vira revenue mas aqui é Vendas status 'completed')
  final int cogs; // Custo das Mercadorias Vendidas (Soma qtde * custo de itens)
  final int operatingExpenses; // Soma total de despesas (expenses)
  
  const DreReport({
    required this.totalRevenue,
    required this.cogs,
    required this.operatingExpenses,
  });

  /// Faturamento - Custo
  int get grossProfit => totalRevenue - cogs;
  
  /// Margem Bruta (em %)
  double get grossMargin => totalRevenue > 0 ? (grossProfit / totalRevenue) * 100.0 : 0.0;
  
  /// Lucro Bruto - Despesas Operacionais
  int get netProfit => grossProfit - operatingExpenses;
  
  /// Margem Líquida (em %)
  double get netMargin => totalRevenue > 0 ? (netProfit / totalRevenue) * 100.0 : 0.0;
}
