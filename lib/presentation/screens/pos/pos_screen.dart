import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product.dart';
import '../../../data/models/debt.dart';
import '../../../data/repositories/sales_repository.dart';
import '../../providers/products_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/debts_provider.dart';

/// Tela do Ponto de Venda (PDV).
/// Exibe grid de produtos + carrinho flutuante.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final List<CartItem> _cart = [];
  String _paymentMethod = 'pix';
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  int get _cartTotal {
    return _cart.fold(0, (sum, item) => sum + item.subtotalForMethod(_paymentMethod));
  }

  int get _cartItemCount {
    return _cart.fold(0, (sum, item) => sum + item.quantity);
  }

  void _addToCart(Product product) {
    setState(() {
      final existing = _cart.indexWhere((c) => c.product.id == product.id);
      if (existing >= 0) {
        _cart[existing].quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  Future<void> _finalizeSale() async {
    if (_cart.isEmpty) return;

    final profile = ref.read(userProfileProvider).value;
    if (profile?.companyId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Venda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Itens:'),
                Text('$_cartItemCount'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pagamento:'),
                Text(_paymentMethod == 'pix' ? 'Pix / Dinheiro' : _paymentMethod == 'card' ? 'Cartão' : 'Fiado'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  'R\$ ${Product.centsToReal(_cartTotal)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true) return;

    String? customerNameForDebt;
    if (_paymentMethod == 'fiado') {
      final nameCtrl = TextEditingController();
      final hasName = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Nome do Cliente'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome para anotar no caderninho',
              hintText: 'Ex: Seu João da Padaria',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (hasName != true) return;
      customerNameForDebt = nameCtrl.text.trim();
    }

    try {
      await ref.read(salesRepositoryProvider).createSale(
        companyId: profile!.companyId!,
        sellerId: profile.id,
        paymentMethod: _paymentMethod,
        totalAmount: _cartTotal,
        items: _cart,
        notes: customerNameForDebt != null ? 'Fiado para: $customerNameForDebt' : null,
      );
      if (customerNameForDebt != null) {
        final debt = Debt(
          companyId: profile.companyId!,
          sellerId: profile.id,
          type: DebtType.receivable,
          category: DebtCategory.customer,
          personName: customerNameForDebt,
          amount: _cartTotal,
          description: 'Venda via PDV ($_cartItemCount itens)',
        );
        await ref.read(debtsProvider.notifier).addDebt(debt);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venda de R\$ ${Product.centsToReal(_cartTotal)} registrada! ✅'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        setState(() => _cart.clear());
        ref.invalidate(productsProvider); // refresh stock
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final productsAsync = ref.watch(productsProvider);

    final userName = ref.watch(userProfileProvider).value?.name.split(' ').first ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(userName.isNotEmpty ? 'PDV • $userName' : 'PDV'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (products) {
          final activeProducts = products.where((p) => p.isActive).toList();

          if (activeProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Nenhum produto ativo', style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Barra de método de pagamento
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'pix', icon: Icon(Icons.pix, size: 18), label: Text('Pix')),
                      ButtonSegment(value: 'card', icon: Icon(Icons.credit_card, size: 18), label: Text('Cartão')),
                      ButtonSegment(value: 'fiado', icon: Icon(Icons.menu_book, size: 18), label: Text('Fiado')),
                    ],
                    selected: {_paymentMethod},
                    onSelectionChanged: (v) => setState(() => _paymentMethod = v.first),
                  ),
                ),
              ),
              // Barra de busca com autocomplete
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const [];
                    final query = textEditingValue.text.toLowerCase();
                    return activeProducts
                        .where((p) => p.name.toLowerCase().contains(query))
                        .map((p) => p.name)
                        .toList();
                  },
                  onSelected: (selected) {
                    setState(() => _searchQuery = selected);
                    _searchController.text = selected;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Sync controller on first build
                    if (controller != _searchController) {
                      controller.text = _searchQuery;
                      _searchController = controller;
                    }
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      onSubmitted: (_) {
                        onFieldSubmitted();
                        FocusScope.of(context).unfocus();
                      },
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Buscar produto...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  controller.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 350),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (ctx, i) {
                              final option = options.elementAt(i);
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.inventory_2_outlined, size: 20),
                                title: Text(option, style: const TextStyle(fontSize: 14)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Grid de produtos
              Expanded(
                child: Builder(
                  builder: (context) {
                    final filteredProducts = _searchQuery.isEmpty
                        ? activeProducts
                        : activeProducts.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                    if (filteredProducts.isEmpty) {
                      return Center(
                        child: Text('Nenhum produto encontrado para "$_searchQuery"', style: theme.textTheme.bodyMedium),
                      );
                    }

                    return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (ctx, i) {
                    final p = filteredProducts[i];
                    final price = _paymentMethod == 'card' ? p.priceCard : p.pricePix;
                    final inCart = _cart.indexWhere((c) => c.product.id == p.id);
                    final qty = inCart >= 0 ? _cart[inCart].quantity : 0;

                    return GestureDetector(
                      onTap: () => _addToCart(p),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: qty > 0 ? const Color(0xFF10B981) : colorScheme.outlineVariant,
                            width: qty > 0 ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Foto ou ícone
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                    child: p.photoUrl != null
                                        ? Image.network(p.photoUrl!, fit: BoxFit.cover, width: double.infinity)
                                        : Center(
                                            child: Icon(
                                              Icons.fastfood_rounded,
                                              size: 28,
                                              color: colorScheme.primary.withValues(alpha: 0.4),
                                            ),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    children: [
                                      Text(
                                        p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'R\$ ${Product.centsToReal(price)}',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: const Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Badge de quantidade
                            if (qty > 0)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$qty',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
                  },
                ),
              ),

              // Carrinho flutuante
              if (_cart.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2)),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Lista compacta do carrinho
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _cart.length,
                            itemBuilder: (ctx, i) {
                              final item = _cart[i];
                              final price = item.subtotalForMethod(_paymentMethod);
                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.product.name}',
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'R\$ ${Product.centsToReal(price)}',
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                                    onPressed: () => _removeFromCart(i),
                                    visualDensity: VisualDensity.compact,
                                    color: Colors.redAccent,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Botão de finalizar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _finalizeSale,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                              icon: const Icon(Icons.check_circle_rounded),
                              label: Text(
                                'Finalizar  •  R\$ ${Product.centsToReal(_cartTotal)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
