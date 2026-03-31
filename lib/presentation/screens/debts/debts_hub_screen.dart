import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/debt.dart';
import '../../../data/models/product.dart';
import '../../providers/debts_provider.dart';
import '../../providers/products_provider.dart';

extension DebtHelpers on Debt {
  bool get isReceivable => type == DebtType.receivable;
  bool get isPending => status == 'pending';
  bool get isSettled => status == 'settled';
  bool get isCustomer => category == DebtCategory.customer;
  bool get isNeighbor => category == DebtCategory.neighbor;
}

class DebtsHubScreen extends ConsumerStatefulWidget {
  const DebtsHubScreen({super.key});

  @override
  ConsumerState<DebtsHubScreen> createState() => _DebtsHubScreenState();
}

class _DebtsHubScreenState extends ConsumerState<DebtsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCustomerDebtModal() {
    final theme = Theme.of(context);
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Novo Fiado (Cliente)', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do Cliente'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Valor Fiado (R\$)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição ou Contato (Opcional)'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final nm = nameCtrl.text.trim();
                            final valStr = amountCtrl.text.replaceAll(',', '.');
                            final val = double.tryParse(valStr) ?? 0.0;
                            if (nm.isEmpty || val <= 0) return;

                            setModalState(() => isLoading = true);
                            try {
                              final debt = Debt(
                                companyId: '', // vai ser injetado no provider
                                sellerId: '',
                                type: DebtType.receivable,
                                category: DebtCategory.customer,
                                personName: nm,
                                amount: (val * 100).toInt(),
                                description: descCtrl.text.trim(),
                              );
                              
                              await ref.read(debtsProvider.notifier).addDebt(debt);
                              if (context.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setModalState(() => isLoading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                              }
                            }
                          },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Salvar Fiado'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddNeighborDebtModal() {
    final theme = Theme.of(context);
    final nameCtrl = TextEditingController();
    final qntyCtrl = TextEditingController(text: '1');
    DebtType type = DebtType.payable; // default peguei
    Product? selectedProduct;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final productsState = ref.watch(productsProvider);
          final activeProducts = productsState.maybeWhen(
            data: (list) => list.where((p) => p.isActive).toList(),
            orElse: () => <Product>[],
          );

          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Acerto Mútua (Vizinho)', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SegmentedButton<DebtType>(
                  segments: const [
                    ButtonSegment(value: DebtType.payable, label: Text('Peguei')),
                    ButtonSegment(value: DebtType.receivable, label: Text('Emprestei')),
                  ],
                  selected: {type},
                  onSelectionChanged: (set) => setModalState(() => type = set.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do Vizinho/Box'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                
                // Dropdown de Produto
                DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(labelText: 'Produto Emprestado'),
                  initialValue: selectedProduct,
                  items: activeProducts.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setModalState(() => selectedProduct = val);
                  },
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: qntyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantidade', suffixText: 'un'),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: isLoading || selectedProduct == null
                        ? null
                        : () async {
                            final nm = nameCtrl.text.trim();
                            final qtd = int.tryParse(qntyCtrl.text) ?? 1;
                            if (nm.isEmpty || qtd <= 0) return;

                            setModalState(() => isLoading = true);
                            try {
                              final debt = Debt(
                                companyId: '', 
                                sellerId: '',
                                type: type,
                                category: DebtCategory.neighbor,
                                personName: nm,
                                productId: selectedProduct!.id,
                                quantity: qtd,
                                description: 'Mútua de ${selectedProduct!.name}',
                              );
                              
                              await ref.read(debtsProvider.notifier).addDebt(debt);
                              if (context.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setModalState(() => isLoading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                              }
                            }
                          },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Salvar Mútua'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettleNeighborModal(Debt debt) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(debt.isReceivable ? 'Baixa de Empréstimo' : 'Devolução de Mútua'),
          content: Text(
            debt.isReceivable 
              ? 'O vizinho ${debt.personName} devolveu ${debt.quantity}x ${debt.productName ?? 'Produto'}?'
              : 'Você devolveu ${debt.quantity}x ${debt.productName ?? 'Produto'} para ${debt.personName}?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(debtsProvider.notifier).settleDebt(debt, SettlementType.cashPayment);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baixa em DINHEIRO (Estoque NÂO alterado)')));
              },
              child: const Text('Pagou em R\$'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(debtsProvider.notifier).settleDebt(debt, SettlementType.productReturn);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mercadoria devolvida! (Estoque atualizado)')));
              },
              child: const Text('Devolveu Produto'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caderneta'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
             Tab(text: 'Fiados (R\$)'),
             Tab(text: 'Mútua (Produtos)'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabController.index == 0 
          ? _showAddCustomerDebtModal 
          : _showAddNeighborDebtModal,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Novo Fiado' : 'Nova Mútua'),
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err\n\n$stack')),
        data: (debts) {
          final customers = debts.where((d) => d.isCustomer).toList();
          final neighbors = debts.where((d) => d.isNeighbor).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _FiadosList(
                debts: customers, 
                onSettle: (d) => ref.read(debtsProvider.notifier).settleCustomerDebt(d),
              ),
              _MutuaList(
                debts: neighbors,
                onSettle: _showSettleNeighborModal,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FiadosList extends StatelessWidget {
  final List<Debt> debts;
  final Function(Debt) onSettle;

  const _FiadosList({required this.debts, required this.onSettle});

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) return const Center(child: Text('Nenhum fiado de clientes.'));

    final pending = debts.where((d) => d.isPending).toList();
    final total = pending.fold<int>(0, (sum, d) => sum + d.amount);

    return Column(
      children: [
        if (pending.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a Receber:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('R\$ ${Product.centsToReal(total)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: debts.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (ctx, i) {
              final d = debts[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: d.isSettled ? Colors.grey.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                  child: Icon(d.isSettled ? Icons.check : Icons.person, color: d.isSettled ? Colors.grey : Colors.green),
                ),
                title: Text(d.personName, style: TextStyle(decoration: d.isSettled ? TextDecoration.lineThrough : null)),
                subtitle: Text(d.description ?? ''),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('R\$ ${Product.centsToReal(d.amount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (d.isPending)
                      InkWell(
                        onTap: () => onSettle(d),
                        child: const Text('Dar Baixa', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    else 
                       const Text('Pago', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MutuaList extends StatelessWidget {
  final List<Debt> debts;
  final Function(Debt) onSettle;

  const _MutuaList({required this.debts, required this.onSettle});

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) return const Center(child: Text('Nenhum acerto com vizinhos.'));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: debts.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (ctx, i) {
        final d = debts[i];
        final isReceivable = d.isReceivable; // I lent
        final color = isReceivable ? Colors.amber.shade700 : Colors.indigo;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: d.isSettled ? Colors.grey.withValues(alpha: 0.2) : color.withValues(alpha: 0.2),
            child: Icon(
              d.isSettled ? Icons.check : (isReceivable ? Icons.arrow_outward : Icons.call_received), 
              color: d.isSettled ? Colors.grey : color,
            ),
          ),
          title: Text(
            d.personName, 
            style: TextStyle(decoration: d.isSettled ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold)
          ),
          subtitle: Text(isReceivable ? 'Você emprestou' : 'Você pegou'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${d.quantity}x ${d.productName ?? 'Produto'}', style: TextStyle(fontWeight: FontWeight.bold, color: d.isSettled ? null : color)),
              if (d.isPending)
                InkWell(
                  onTap: () => onSettle(d),
                  child: Text('Baixar', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              else 
                 Text(d.settlementType == SettlementType.cashPayment ? 'Pago (R\$)' : 'Devolvido', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}
