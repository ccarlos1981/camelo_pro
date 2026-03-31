import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expenses_repository.dart';
import 'user_profile_provider.dart';

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(() {
  return ExpensesNotifier();
});

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    final profile = ref.watch(userProfileProvider).value;
    if (profile == null || profile.companyId == null) {
      return [];
    }
    return ref.read(expensesRepositoryProvider).getExpenses(profile.companyId!);
  }

  Future<void> addExpense({
    required String description,
    required int amount,
    required DateTime expenseDate,
  }) async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null || profile.companyId == null) return;

    final repo = ref.read(expensesRepositoryProvider);
    final prev = state.value ?? [];

    // Optimistic UI
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempExpense = Expense(
      id: tempId,
      companyId: profile.companyId!,
      description: description,
      amount: amount,
      expenseDate: expenseDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = AsyncData([tempExpense, ...prev]);

    try {
      final actualExpense = await repo.createExpense(tempExpense);
      state = AsyncData([
        actualExpense,
        ...prev,
      ]);
    } catch (e) {
      state = AsyncData(prev); // rollback
      rethrow;
    }
  }

  Future<void> removeExpense(String id) async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null || profile.companyId == null) return;

    final repo = ref.read(expensesRepositoryProvider);
    final prev = state.value ?? [];

    state = AsyncData(prev.where((e) => e.id != id).toList());

    try {
      await repo.deleteExpense(id, profile.companyId!);
    } catch (e) {
      state = AsyncData(prev); // rollback
      rethrow;
    }
  }
}
