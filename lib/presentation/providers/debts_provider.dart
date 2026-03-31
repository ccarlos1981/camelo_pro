import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/debt.dart';
import '../../data/repositories/debts_repository.dart';
import 'user_profile_provider.dart';

final debtsProvider = AsyncNotifierProvider<DebtsNotifier, List<Debt>>(() {
  return DebtsNotifier();
});

class DebtsNotifier extends AsyncNotifier<List<Debt>> {
  @override
  Future<List<Debt>> build() async {
    return _fetchDebts();
  }

  Future<List<Debt>> _fetchDebts() async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null || profile.companyId == null) return [];
    final repo = ref.read(debtsRepositoryProvider);
    return repo.fetchDebts(profile.companyId!);
  }

  Future<void> addDebt(Debt debt) async {
    final profile = await ref.read(userProfileProvider.future);
    if (profile == null || profile.companyId == null) return;
    
    // Inject companyId and sellerId 
    final newDebt = debt.copyWith(
      companyId: profile.companyId,
      sellerId: profile.id,
    );

    final repo = ref.read(debtsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.createDebt(newDebt);
      final current = await _fetchDebts(); // Refresh list to get relationships right (productName)
      return current;
    });
  }

  Future<void> settleDebt(Debt debt, SettlementType type) async {
    final repo = ref.read(debtsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.settleDebt(debt, settlementType: type);
      return _fetchDebts();
    });
  }

  Future<void> settleCustomerDebt(Debt debt) async {
    final repo = ref.read(debtsRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.settleDebt(debt); // Customer debts dont need SettlementType since it sets status=settled only
      return _fetchDebts();
    });
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDebts());
  }
}
