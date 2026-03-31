import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product.dart'; // used for centsToReal
import '../../providers/balance_provider.dart';
import '../../widgets/add_expense_modal.dart';

class BalanceMediumScreen extends ConsumerWidget {
  const BalanceMediumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);
    final filter = ref.watch(balanceFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão Medium (Tática)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_rounded),
            onPressed: () => showAddExpenseModal(context),
            tooltip: 'Lançar Despesa',
          ),
        ],
      ),
      body: balanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
        data: (dre) {
          return CustomScrollView(
            slivers: [
              // Barra de filtros
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: BalanceFilter.values.map((f) {
                        final isSelected = filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getFilterName(f)),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) ref.read(balanceFilterProvider.notifier).setFilter(f);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _AnalyticCard(
                      title: 'Faturamento vs CMV',
                      children: [
                        _RowStat('Faturamento Bruto', dre.totalRevenue, Colors.blue),
                        _RowStat('Custo p/ Reposição (CMV)', dre.cogs, Colors.orange),
                        const Divider(height: 32),
                        _RowStat('Lucro Bruto (Margem de Ganho)', dre.grossProfit, Colors.green),
                        Text(
                          'Margem Bruta (Markup Média): ${dre.grossMargin.toStringAsFixed(1)}%',
                          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AnalyticCard(
                      title: 'Despesas e Resultado Líquido',
                      children: [
                        _RowStat('Despesas Operacionais', dre.operatingExpenses, Colors.red),
                        const Divider(height: 32),
                        _RowStat('Saldo Líquido', dre.netProfit, dre.netProfit >= 0 ? Colors.green : Colors.red),
                        Text(
                          'Margem Líquida Real: ${dre.netMargin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: dre.netProfit >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getFilterName(BalanceFilter f) {
    switch (f) {
      case BalanceFilter.today: return 'Hoje';
      case BalanceFilter.thisWeek: return 'Nesta Semana';
      case BalanceFilter.thisMonth: return 'Neste Mês';
      case BalanceFilter.thisYear: return 'Neste Ano';
    }
  }
}

class _AnalyticCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _AnalyticCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RowStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _RowStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            'R\$ ${Product.centsToReal(value.abs())}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
