import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dre_report.dart';
import '../../data/models/sale.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/sales_repository.dart';
import '../../data/repositories/expenses_repository.dart';
import 'user_profile_provider.dart';

enum BalanceFilter { today, thisWeek, thisMonth, thisYear }

class BalanceFilterNotifier extends Notifier<BalanceFilter> {
  @override
  BalanceFilter build() => BalanceFilter.thisMonth;

  void setFilter(BalanceFilter filter) => state = filter;
}

final balanceFilterProvider = NotifierProvider<BalanceFilterNotifier, BalanceFilter>(() {
  return BalanceFilterNotifier();
});

final balanceProvider = AsyncNotifierProvider<BalanceNotifier, DreReport>(() {
  return BalanceNotifier();
});

class BalanceNotifier extends AsyncNotifier<DreReport> {
  @override
  Future<DreReport> build() async {
    final profile = ref.watch(userProfileProvider).value;
    final filter = ref.watch(balanceFilterProvider);

    if (profile == null || profile.companyId == null) {
      return const DreReport(totalRevenue: 0, cogs: 0, operatingExpenses: 0);
    }

    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (filter) {
      case BalanceFilter.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case BalanceFilter.thisWeek:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case BalanceFilter.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case BalanceFilter.thisYear:
        start = DateTime(now.year, 1, 1);
        break;
    }

    final salesRepo = ref.read(salesRepositoryProvider);
    final expRepo = ref.read(expensesRepositoryProvider);

    final futures = await Future.wait([
      salesRepo.fetchSalesBetween(profile.companyId!, start, end),
      expRepo.getExpensesBetween(profile.companyId!, start, end),
    ]);

    final sales = futures[0] as List<Sale>;
    final expenses = futures[1] as List<Expense>;

    int totalRev = 0;
    int cogs = 0;
    for (final sale in sales) {
      totalRev += sale.totalAmount;
      final items = sale.items ?? [];
      for (final item in items) {
        cogs += item.quantity * item.unitCost;
      }
    }

    int totalExp = 0;
    for (final exp in expenses) {
      totalExp += exp.amount;
    }

    return DreReport(
      totalRevenue: totalRev,
      cogs: cogs,
      operatingExpenses: totalExp,
    );
  }
}
