import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/customers_provider.dart';
import '../../providers/user_profile_provider.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomer(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Novo'),
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (customers) {
          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Nenhum cliente cadastrado', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('Cadastre clientes para enviar promoções.', style: theme.textTheme.bodySmall),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: customers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final c = customers[i];
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
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        c.name[0].toUpperCase(),
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          if (c.phone != null)
                            Text(c.phone!, style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            )),
                        ],
                      ),
                    ),
                    if (c.whatsappNumber != null)
                      IconButton(
                        icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                        tooltip: 'Enviar WhatsApp',
                        onPressed: () => _sendWhatsApp(context, c.whatsappNumber!, c.name),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'promo') {
                          _showPromoDialog(context, c.whatsappNumber, c.name);
                        } else if (v == 'delete') {
                          await ref.read(customersProvider.notifier).deleteCustomer(c.id);
                        }
                      },
                      itemBuilder: (_) => [
                        if (c.whatsappNumber != null)
                          const PopupMenuItem(value: 'promo', child: Text('Enviar Promoção')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCustomer(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final theme = Theme.of(context);
    final companyId = ref.read(userProfileProvider).value?.companyId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Novo Cliente', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'WhatsApp (opcional)',
                hintText: '11999998888',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nome é obrigatório.')),
                    );
                    return;
                  }
                  await ref.read(customersProvider.notifier).addCustomer(
                    companyId: companyId ?? '',
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${nameCtrl.text.trim()} cadastrado! ✅'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Salvar Cliente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendWhatsApp(BuildContext context, String number, String name) async {
    final url = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent('Olá $name! 👋')}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showPromoDialog(BuildContext context, String? number, String name) {
    if (number == null) return;
    final msgCtrl = TextEditingController(text: 'Olá $name! 🎉\n\nTemos uma promoção especial para você!\n\n');
    final theme = Theme.of(context); // ignore: unused_local_variable

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar Promoção'),
        content: TextField(
          controller: msgCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Mensagem',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton.icon(
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Enviar'),
            onPressed: () async {
              Navigator.pop(ctx);
              final url = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(msgCtrl.text)}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
