import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product.dart'; // used for centsToReal
import '../../providers/balance_provider.dart';
import '../../widgets/add_expense_modal.dart';

class BalanceLightScreen extends ConsumerWidget {
  const BalanceLightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(balanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão Light'),
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
          final isProfit = dre.netProfit >= 0;
          final mainColor = isProfit ? Colors.green.shade600 : Colors.red.shade600;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Margem / Lucro Líquido Gigante
                Center(
                  child: Column(
                    children: [
                      Text(
                        'SEU RESULTADO OPERACIONAL',
                        style: theme.textTheme.labelLarge?.copyWith(
                          letterSpacing: 2,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'R\$ ${Product.centsToReal(dre.netProfit.abs())}',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: mainColor,
                        ),
                      ),
                      Text(
                        dre.netProfit >= 0 ? 'NO AZUL 🚀' : 'NO VERMELHO 🔻',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),

                // Cartões descritivos
                _InfoBlock(
                  label: 'Faturamento Bruto',
                  value: dre.totalRevenue,
                  color: Colors.blue.shade600,
                  icon: Icons.payments_rounded,
                ),
                const SizedBox(height: 16),
                _InfoBlock(
                  label: '(-) Custo da Mercadoria',
                  value: dre.cogs,
                  color: Colors.orange.shade600,
                  icon: Icons.inventory_2_rounded,
                ),
                const SizedBox(height: 16),
                _InfoBlock(
                  label: '(-) Despesas Operacionais',
                  value: dre.operatingExpenses,
                  color: Colors.red.shade500,
                  icon: Icons.receipt_long_rounded,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _InfoBlock({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'R\$ ${Product.centsToReal(value)}',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
