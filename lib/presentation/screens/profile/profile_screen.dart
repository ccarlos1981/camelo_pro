import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/subscription_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará fazer login novamente para entrar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;

    final name = profile?.name ?? user?.userMetadata?['full_name'] ?? 'Usuário';
    final phone = user?.phone ?? profile?.phone ?? '';
    final company = user?.userMetadata?['company_name'] ?? '';
    final isOwner = profile?.isOwner ?? false;
    final roleName = isOwner ? 'Proprietário' : 'Vendedor';
    final roleColor = isOwner ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final roleIcon = isOwner ? Icons.shield_rounded : Icons.point_of_sale_rounded;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 36, color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (company.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(company, style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.primary)),
            ),
          ],
          const SizedBox(height: 12),

          // Role badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleIcon, size: 16, color: roleColor),
                  const SizedBox(width: 6),
                  Text(
                    roleName,
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Info tiles
          _InfoTile(icon: Icons.phone_outlined, label: 'WhatsApp', value: phone),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'Função',
            value: roleName,
            valueColor: roleColor,
          ),
          const SizedBox(height: 12),
          if (isOwner)
            Builder(
              builder: (context) {
                final subAsync = ref.watch(subscriptionProvider);
                final sub = subAsync.value;
                String planText;
                Color planColor;
                if (sub == null) {
                  planText = 'Carregando...';
                  planColor = colorScheme.tertiary;
                } else if (sub.isPaid && sub.isActive) {
                  planText = '${sub.planLabel} — Ativo';
                  planColor = const Color(0xFF7C3AED);
                } else if (sub.isTrial && sub.isActive) {
                  planText = 'Trial — ${sub.daysRemaining} dias restantes';
                  planColor = colorScheme.tertiary;
                } else {
                  planText = 'Expirado — Assine agora';
                  planColor = Colors.redAccent;
                }
                return _InfoTile(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Plano',
                  value: planText,
                  valueColor: planColor,
                );
              },
            ),
          if (isOwner) const SizedBox(height: 12),

          // Permissões do funcionário
          if (!isOwner && profile != null) ...[
            Text(
              'Suas Permissões',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _permBadge('Registrar vendas', profile.permissions.canRegisterSales),
            _permBadge('Cadastrar clientes', profile.permissions.canManageCustomers),
            _permBadge('Compartilhar promoções', profile.permissions.canSharePromotions),
            _permBadge('Gerenciar produtos', profile.permissions.canManageProducts),
            _permBadge('Ver relatórios', profile.permissions.canViewReports),
            _permBadge('Ver despesas', profile.permissions.canViewExpenses),
            const SizedBox(height: 20),
          ],

          // Logout
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair da Conta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              minimumSize: const Size(double.infinity, 54),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _permBadge(String label, bool enabled) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(
          enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 18,
          color: enabled ? const Color(0xFF10B981) : Colors.grey,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: enabled ? null : Colors.grey,
            fontWeight: enabled ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
