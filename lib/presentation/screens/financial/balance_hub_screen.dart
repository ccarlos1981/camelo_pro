import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/add_expense_modal.dart';

class BalanceHubScreen extends StatelessWidget {
  const BalanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Na HomeScreen eu removi AppBar ou mantive? O OwnerShell lida com AppBar se tiver,
    // mas telas filhas como HomeScreen tem AppBar próprio. 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balanço Financeiro'),
        actions: [
          IconButton(
            tooltip: 'Lançar Despesa',
            icon: const Icon(Icons.add_shopping_cart_rounded),
            onPressed: () => showAddExpenseModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Escolha a visão do seu DRE',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione a granularidade dos dados financeiros que deseja visualizar agora.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            _ViewOptionCard(
              title: 'Visão Light',
              description: 'Resumo rápido. Faturamento, Despesas e Lucro Líquido em letras garrafais. Ideal para fechamento de caixa.',
              icon: Icons.flash_on_rounded,
              color: Colors.amber.shade600,
              onTap: () => context.push('/balance/light'),
            ),
            const SizedBox(height: 16),
            
            _ViewOptionCard(
              title: 'Visão Medium',
              description: 'Análise tática. Filtragem temporal e detalhamento do custo de mercadoria (CMV).',
              icon: Icons.bar_chart_rounded,
              color: Colors.blue.shade600,
              onTap: () => context.push('/balance/medium'),
            ),
            const SizedBox(height: 16),
            
            _ViewOptionCard(
              title: 'Visão Full (Livro Contábil)',
              description: 'Extrato completo. Todas as despesas individuais lançadas e histórico contábil profundo.',
              icon: Icons.account_balance_rounded,
              color: Colors.purple.shade600,
              onTap: () => context.push('/balance/full'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddExpenseModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Lançar Despesa'),
      ),
    );
  }
}

class _ViewOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ViewOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
