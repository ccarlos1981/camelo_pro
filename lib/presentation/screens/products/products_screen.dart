import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/product.dart';
import '../../providers/products_provider.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(productsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Produto'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('Erro ao carregar produtos', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.read(productsProvider.notifier).refresh(),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return _EmptyState(onAdd: () => context.push('/products/add'));
          }

          final active = products.where((p) => p.isActive).toList();
          final inactive = products.where((p) => !p.isActive).toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
                  indicatorColor: colorScheme.primary,
                  tabs: [
                    Tab(text: 'Ativos (${active.length})'),
                    Tab(text: 'Inativos (${inactive.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ProductGrid(products: active, ref: ref),
                      _ProductGrid(products: inactive, ref: ref),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Sua vitrine está vazia!',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre seu primeiro produto para começar a vender.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Cadastrar Primeiro Produto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final WidgetRef ref;

  const _ProductGrid({required this.products, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          'Nenhum produto nesta lista.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _ProductCard(product: products[index], ref: ref);
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final WidgetRef ref;

  const _ProductCard({required this.product, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          context.push('/products/edit', extra: product);
        },
        onLongPress: () => _showOptions(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto ou placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: colorScheme.primary.withValues(alpha: 0.05),
                child: product.photoUrl != null
                    ? Image.network(product.photoUrl!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          product.isCombo ? Icons.fastfood_rounded : Icons.image_outlined,
                          size: 40,
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.isCombo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('COMBO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                      ),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        // Preço Pix
                        Icon(Icons.pix, size: 12, color: const Color(0xFF00BDAE)),
                        const SizedBox(width: 2),
                        Text(
                          'R\$ ${Product.centsToReal(product.pricePix)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.credit_card, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 2),
                        Text(
                          'R\$ ${Product.centsToReal(product.priceCard)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(product.isActive ? Icons.visibility_off : Icons.visibility),
              title: Text(product.isActive ? 'Desativar Produto' : 'Reativar Produto'),
              onTap: () {
                ref.read(productsProvider.notifier).toggleActive(product.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Excluir Produto', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                ref.read(productsProvider.notifier).deleteProduct(product.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
