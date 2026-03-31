import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_profile_provider.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Equipe'),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/team/ranking');
            },
            icon: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
            tooltip: 'Ranking e Metas',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteModal(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Adicionar'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar perfil: $e')),
        data: (profile) {
          final companyId = profile?.companyId;
          if (companyId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Empresa não encontrada', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('Configure sua empresa primeiro.', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<UserProfile>>(
            future: ref.read(profileRepositoryProvider).fetchTeamMembers(companyId),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text('Erro: ${snap.error}', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(userProfileProvider),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }
              final members = snap.data ?? [];
              if (members.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('Nenhum membro na equipe', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Toque em + para adicionar um funcionário.', style: theme.textTheme.bodySmall),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: members.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final member = members[i];
                  return _MemberCard(member: member, ref: ref);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showInviteModal(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final theme = Theme.of(context);
    var isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cadastrar Funcionário', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('A senha inicial será 123456', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Celular (DDD + número)',
                  hintText: '11999998888',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Preencha nome e telefone.')),
                            );
                            return;
                          }
                          setModalState(() => isLoading = true);
                          try {
                            await ref.read(profileRepositoryProvider).inviteEmployee(
                              phone: phoneCtrl.text.trim(),
                              name: nameCtrl.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${nameCtrl.text.trim()} cadastrado com sucesso! ✅'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  icon: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.person_add_rounded),
                  label: Text(isLoading ? 'Cadastrando...' : 'Cadastrar Funcionário'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserProfile member;
  final WidgetRef ref;
  const _MemberCard({required this.member, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = member.isOwner;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isOwner
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : theme.colorScheme.tertiary.withValues(alpha: 0.15),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOwner ? theme.colorScheme.primary : theme.colorScheme.tertiary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOwner ? 'Dono' : 'Funcionário',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isOwner ? theme.colorScheme.primary : theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (member.phone != null)
                  Text(member.phone!, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  )),
              ],
            ),
          ),
          if (!isOwner)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'permissions') {
                  _showPermissionsDialog(context, member);
                } else if (value == 'remove') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remover funcionário?'),
                      content: Text('${member.name} perderá acesso à equipe.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Remover', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(profileRepositoryProvider).removeFromTeam(member.id);
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'permissions', child: Text('Permissões')),
                const PopupMenuItem(value: 'remove', child: Text('Remover', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
        ],
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context, UserProfile member) {
    var perms = member.permissions;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Permissões de ${member.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _permToggle('Cadastrar produtos', perms.canManageProducts, (v) {
                  setDialogState(() => perms = perms.copyWith(canManageProducts: v));
                }),
                _permToggle('Registrar vendas', perms.canRegisterSales, (v) {
                  setDialogState(() => perms = perms.copyWith(canRegisterSales: v));
                }),
                _permToggle('Ver relatórios', perms.canViewReports, (v) {
                  setDialogState(() => perms = perms.copyWith(canViewReports: v));
                }),
                _permToggle('Ver despesas', perms.canViewExpenses, (v) {
                  setDialogState(() => perms = perms.copyWith(canViewExpenses: v));
                }),
                _permToggle('Cadastrar clientes', perms.canManageCustomers, (v) {
                  setDialogState(() => perms = perms.copyWith(canManageCustomers: v));
                }),
                _permToggle('Compartilhar promoções', perms.canSharePromotions, (v) {
                  setDialogState(() => perms = perms.copyWith(canSharePromotions: v));
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                await ref.read(profileRepositoryProvider).updatePermissions(member.id, perms.toJson());
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permissões atualizadas! ✅'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _permToggle(String label, bool value, ValueChanged<bool> onChanged) {
  return SwitchListTile(
    title: Text(label),
    value: value,
    onChanged: onChanged,
    contentPadding: EdgeInsets.zero,
  );
}
