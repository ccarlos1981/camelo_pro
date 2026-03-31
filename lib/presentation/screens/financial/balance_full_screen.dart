import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product.dart'; // used for centsToReal
import '../../providers/balance_provider.dart';
import '../../providers/expenses_provider.dart';
import '../../widgets/add_expense_modal.dart';
import 'package:intl/intl.dart';

class BalanceFullScreen extends ConsumerWidget {
  const BalanceFullScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dreAsync = ref.watch(balanceProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão Full (Livro Contábil)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_rounded),
            onPressed: () => showAddExpenseModal(context),
            tooltip: 'Lançar Despesa',
          ),
        ],
      ),
      body: dreAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro DRE: $err')),
        data: (dre) {
          return CustomScrollView(
            slivers: [
              // Header consolidado
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Faturamento no Mês', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('R\$ ${Product.centsToReal(dre.totalRevenue)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Custos Deduzidos (CMV)', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('- R\$ ${Product.centsToReal(dre.cogs)}', style: const TextStyle(color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Despesas Totais', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('- R\$ ${Product.centsToReal(dre.operatingExpenses)}', style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('LUCRO LÍQUIDO', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          Text(
                            'R\$ ${Product.centsToReal(dre.netProfit)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: dre.netProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text('Extrato de Despesas Operacionais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              expensesAsync.when(
                loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                error: (err, _) => SliverToBoxAdapter(child: Center(child: Text('Erro Exp: $err'))),
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nenhuma despesa lançada no histórico.'),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final e = expenses[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            child: const Icon(Icons.receipt_long_rounded, color: Colors.red),
                          ),
                          title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('dd/MM/yyyy').format(e.expenseDate)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '- R\$ ${Product.centsToReal(e.amount)}',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () {
                                  ref.read(expensesProvider.notifier).removeExpense(e.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: expenses.length,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
