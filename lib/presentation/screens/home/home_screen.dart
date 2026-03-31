import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/sales_repository.dart';
import '../../providers/products_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/subscription_provider.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profile = ref.watch(userProfileProvider).value;
    final user = Supabase.instance.client.auth.currentUser;
    final name = profile?.name ?? user?.userMetadata?['full_name'] ?? 'Vendedor(a)';
    final firstName = name.split(' ').first;
    final isOwner = profile?.isOwner ?? true;
    final perms = profile?.permissions;

    final productsAsync = ref.watch(productsProvider);

    // Dados dinâmicos baseados na lista de produtos
    final products = productsAsync.value ?? [];
    final activeProducts = products.where((p) => p.isActive).toList();
    final lowStock = activeProducts.where((p) => p.stockQuantity <= 3).length;

    // Dados de vendas do dia
    final companyId = profile?.companyId;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Camelo Pro'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isOwner ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOwner ? Icons.shield_rounded : Icons.point_of_sale_rounded,
                    size: 12,
                    color: isOwner ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOwner ? 'Admin' : 'Vendedor',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOwner ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saudação
            Text(
              'Olá, $firstName! 👋',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              isOwner
                  ? 'Painel do proprietário — gerencie sua barraca.'
                  : 'Seu painel de vendas — boas vendas!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Cards de resumo
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.inventory_2_rounded,
                    label: 'Produtos',
                    value: '${activeProducts.length}',
                    color: colorScheme.primary,
                    onTap: () => _goToTab(context, 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: companyId == null
                      ? _SummaryCard(
                          icon: Icons.shopping_cart_rounded,
                          label: 'Vendas Hoje',
                          value: '...',
                          color: const Color(0xFF10B981),
                        )
                      : FutureBuilder<Map<String, dynamic>>(
                          future: ref.read(salesRepositoryProvider).fetchTodaySummary(companyId),
                          builder: (ctx, snap) {
                            final count = snap.data?['count'] ?? 0;
                            return _SummaryCard(
                              icon: Icons.shopping_cart_rounded,
                              label: 'Vendas Hoje',
                              value: '$count',
                              color: const Color(0xFF10B981),
                            );
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: companyId == null
                      ? _SummaryCard(
                          icon: Icons.attach_money_rounded,
                          label: 'Faturamento',
                          value: 'R\$ 0,00',
                          color: const Color(0xFFF59E0B),
                        )
                      : FutureBuilder<Map<String, dynamic>>(
                          future: ref.read(salesRepositoryProvider).fetchTodaySummary(companyId),
                          builder: (ctx, snap) {
                            final total = snap.data?['total'] ?? 0;
                            return _SummaryCard(
                              icon: Icons.attach_money_rounded,
                              label: 'Faturamento',
                              value: 'R\$ ${Product.centsToReal(total)}',
                              color: const Color(0xFFF59E0B),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Estoque Baixo',
                    value: '$lowStock',
                    color: lowStock > 0 ? Colors.redAccent : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Banner de assinatura dinâmico
            _SubscriptionBanner(ref: ref, colorScheme: colorScheme),

            const SizedBox(height: 32),

            // Ações rápidas
            Text(
              'Ações Rápidas',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Ações filtradas por permissão
            if (isOwner || (perms?.canViewReports ?? false))
              _QuickActionTile(
                icon: Icons.emoji_events_rounded,
                title: 'Ranking de Vendas',
                subtitle: 'Veja quem mais vendeu e gráficos',
                color: Colors.amber.shade700,
                onTap: () => context.push('/team/ranking'),
              ),
            if (isOwner || (perms?.canViewReports ?? false))
              const SizedBox(height: 12),

            if (isOwner || (perms?.canManageProducts ?? false))
              _QuickActionTile(
                icon: Icons.add_box_rounded,
                title: 'Cadastrar Produto',
                subtitle: 'Adicione um item ao seu estoque',
                color: colorScheme.primary,
                onTap: () => context.push('/products/add'),
              ),
            if (isOwner || (perms?.canManageProducts ?? false))
              const SizedBox(height: 12),

            if (isOwner || (perms?.canManageProducts ?? false))
              _QuickActionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Bipar Código de Barras',
                subtitle: 'Escaneie para entrada ou saída rápida',
                color: const Color(0xFF10B981),
                onTap: () => context.push('/products/scanner'),
              ),
            if (isOwner || (perms?.canManageProducts ?? false))
              const SizedBox(height: 12),

            if (isOwner || (perms?.canRegisterSales ?? false))
              _QuickActionTile(
                icon: Icons.receipt_long_rounded,
                title: 'Registrar Venda',
                subtitle: 'Abra o ponto de venda',
                color: const Color(0xFFF59E0B),
                onTap: () => context.push('/owner-pos'),
              ),
            if (isOwner || (perms?.canRegisterSales ?? false))
              const SizedBox(height: 12),

            if (isOwner || (perms?.canViewExpenses ?? false))
              _QuickActionTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Lançar Despesas / DRE',
                subtitle: 'Acompanhe seu lucro e gastos',
                color: Colors.purple.shade600,
                onTap: () => context.push('/balance'),
              ),
            if (isOwner || (perms?.canViewExpenses ?? false))
              const SizedBox(height: 12),

            _QuickActionTile(
              icon: Icons.menu_book_rounded,
              title: 'Caderno / Fiados',
              subtitle: 'Gerencie dívidas de clientes e da barraca',
              color: Colors.blueAccent,
              onTap: () => context.push('/debts'),
            ),
          ],
        ),
      ),
    );
  }

  /// Navega para uma aba específica do BottomNavigationBar.
  void _goToTab(BuildContext context, int index) {
    final shell = StatefulNavigationShell.of(context);
    shell.goBranch(index);
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionBanner extends StatelessWidget {
  final WidgetRef ref;
  final ColorScheme colorScheme;

  const _SubscriptionBanner({required this.ref, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionProvider);

    return subAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (sub) {
        if (sub == null) return const SizedBox.shrink();

        // Determinar estado visual
        IconData icon;
        String title;
        String subtitle;
        List<Color> gradientColors;

        if (sub.isPaid && sub.isActive) {
          // Assinante ativo
          icon = Icons.diamond_rounded;
          title = 'Camelo Pro Ativo 💎';
          subtitle = 'Seu plano está ativo. Boas vendas!';
          gradientColors = [const Color(0xFF7C3AED), const Color(0xFF6D28D9)];
        } else if (sub.isTrial && sub.isTrialUrgent) {
          // Trial prestes a expirar (≤ 7 dias)
          icon = Icons.warning_amber_rounded;
          title = '⚠️ Teste acaba em ${sub.daysRemaining} dias!';
          subtitle = 'Assine agora e não perca seus dados.';
          gradientColors = [Colors.orange.shade700, Colors.red.shade600];
        } else if (sub.isTrial && sub.isActive) {
          // Trial ativo normal
          icon = Icons.rocket_launch_rounded;
          title = 'Teste Grátis Ativo!';
          subtitle = '${sub.daysRemaining} dias restantes para explorar tudo.';
          gradientColors = [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)];
        } else {
          // Expirado
          icon = Icons.lock_rounded;
          title = 'Seu acesso expirou 🔒';
          subtitle = 'Toque para assinar e continuar vendendo.';
          gradientColors = [Colors.grey.shade700, Colors.grey.shade600];
        }

        return GestureDetector(
          onTap: sub.isExpired ? () => context.push('/paywall') : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (sub.isExpired)
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}
