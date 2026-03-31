import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expenses_provider.dart';

void showAddExpenseModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _AddExpenseForm(),
  );
}

class _AddExpenseForm extends ConsumerStatefulWidget {
  const _AddExpenseForm();

  @override
  ConsumerState<_AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends ConsumerState<_AddExpenseForm> {
  final _amountCtrl = TextEditingController();
  String _selectedDescription = '';
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Pegamos todas as descrições únicas já usadas
    final expenses = ref.watch(expensesProvider).value ?? [];
    final existingCategories = expenses
        .map((e) => e.description.trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();

    // Default suggestions se for conta nova
    if (existingCategories.isEmpty) {
      existingCategories.addAll([
        'Almoço', 'Frete', 'Gasolina', 'Embalagem', 'Imposto', 'Manutenção'
      ]);
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Lançar Despesa', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          DropdownMenu<String>(
            controller: _descCtrl,
            width: MediaQuery.of(context).size.width - 48,
            label: const Text('Categoria / Descrição'),
            hintText: 'Digite ou escolha na lista',
            onSelected: (val) {
              if (val != null) {
                _selectedDescription = val;
              }
            },
            dropdownMenuEntries: existingCategories.map((c) {
              return DropdownMenuEntry(value: c, label: c);
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor (R\$)',
              prefixText: 'R\$ ',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : _saveTask,
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Registrar'),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _saveTask() async {
    final rawDesc = _descCtrl.text.trim();
    final finalDesc = rawDesc.isNotEmpty ? rawDesc : _selectedDescription;

    final val = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    
    if (finalDesc.isEmpty || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a descrição e um valor válido.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(expensesProvider.notifier).addExpense(
        description: finalDesc,
        amount: (val * 100).toInt(),
        expenseDate: DateTime.now(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: \$e')),
        );
      }
    }
  }
}
