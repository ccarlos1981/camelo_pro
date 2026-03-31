import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/product.dart';
import '../../providers/products_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? initialBarcode;
  const AddProductScreen({super.key, this.initialBarcode});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _markupController = TextEditingController();
  final _pricePixController = TextEditingController();
  final _priceCardController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  bool _isCombo = false;
  bool _isLoading = false;
  File? _photo;

  @override
  void initState() {
    super.initState();
    if (widget.initialBarcode != null) {
      _barcodeController.text = widget.initialBarcode!;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome ao seu produto.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final product = Product(
        id: '', // será gerado pelo banco
        companyId: '', // será preenchido pelo repository
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        name: name,
        buyPrice: Product.realToCents(_buyPriceController.text),
        grossCostMarkup: Product.realToCents(_markupController.text),
        pricePix: Product.realToCents(_pricePixController.text),
        priceCard: Product.realToCents(_priceCardController.text),
        isCombo: _isCombo,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
      );

      await ref.read(productsProvider.notifier).addProduct(product, photo: _photo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name cadastrado com sucesso! 🎉'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _markupController.dispose();
    _pricePixController.dispose();
    _priceCardController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Cálculo de lucro dinâmico
    final buyPrice = Product.realToCents(_buyPriceController.text);
    final markup = Product.realToCents(_markupController.text);
    final totalCost = buyPrice + markup;
    final pricePix = Product.realToCents(_pricePixController.text);
    final profitPix = pricePix - totalCost;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Produto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Foto ──
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    image: _photo != null
                        ? DecorationImage(image: FileImage(_photo!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _photo == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 40, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              'Toque para adicionar foto',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 24),

              // ── Info básica ──
              _SectionTitle(title: 'Informações', icon: Icons.edit_rounded),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                  hintText: 'Ex: Guaraná Antarctica 350ml',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _barcodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Código de Barras (opcional)',
                  prefixIcon: const Icon(Icons.qr_code_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    onPressed: () => context.push('/products/scanner'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Este item é um Combo'),
                subtitle: const Text('Agrupamento de produtos (ex: Pipoca + Refri)'),
                value: _isCombo,
                onChanged: (v) => setState(() => _isCombo = v),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // ── Custos ──
              _SectionTitle(title: 'Custos', icon: Icons.payments_outlined),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _buyPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Custo (R\$)',
                        hintText: '3,50',
                        prefixIcon: Icon(Icons.shopping_cart_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _markupController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Custo Extra (R\$)',
                        hintText: '0,50',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              if (totalCost > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Custo total por unidade: R\$ ${Product.centsToReal(totalCost)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Preços de Venda ──
              _SectionTitle(title: 'Preço de Venda', icon: Icons.sell_outlined),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pricePixController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Pix / Dinheiro (R\$)',
                        hintText: '5,00',
                        prefixIcon: Icon(Icons.pix, color: Color(0xFF00BDAE)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _priceCardController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                      decoration: const InputDecoration(
                        labelText: 'Cartão (R\$)',
                        hintText: '6,00',
                        prefixIcon: Icon(Icons.credit_card_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              if (pricePix > 0 && totalCost > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: profitPix > 0
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          profitPix > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 18,
                          color: profitPix > 0 ? const Color(0xFF10B981) : Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profitPix > 0
                              ? 'Lucro no Pix: R\$ ${Product.centsToReal(profitPix)} por unidade'
                              : 'Prejuízo no Pix: R\$ ${Product.centsToReal(profitPix.abs())} por unidade',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: profitPix > 0 ? const Color(0xFF10B981) : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Estoque ──
              _SectionTitle(title: 'Estoque', icon: Icons.inventory_2_outlined),
              const SizedBox(height: 12),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Quantidade em Estoque',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ),

              const SizedBox(height: 40),

              // ── Botão Salvar ──
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_rounded),
                  label: Text(_isLoading ? 'Salvando...' : 'Salvar Produto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
