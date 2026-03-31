import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/seller_rank.dart';
import '../../data/repositories/financial_repository.dart';
import '../../data/repositories/profile_repository.dart';
import 'user_profile_provider.dart';

/// Filtros de período para o ranking
enum RankingPeriod { today, thisWeek, thisMonth }

/// Provider do filtro selecionado
class RankingPeriodNotifier extends Notifier<RankingPeriod> {
  @override
  RankingPeriod build() => RankingPeriod.thisMonth;

  void setPeriod(RankingPeriod period) => state = period;
}

final rankingPeriodProvider = NotifierProvider<RankingPeriodNotifier, RankingPeriod>(() {
  return RankingPeriodNotifier();
});

/// Provider principal do ranking (responde ao filtro)
final rankingProvider = FutureProvider.autoDispose<List<SellerRank>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null || profile.companyId == null) return [];

  final period = ref.watch(rankingPeriodProvider);
  final financialRepo = ref.read(financialRepositoryProvider);
  final profileRepo = ref.read(profileRepositoryProvider);

  // Calcular período
  final now = DateTime.now();
  late DateTime start;
  late DateTime end;

  switch (period) {
    case RankingPeriod.today:
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;
    case RankingPeriod.thisWeek:
      final weekday = now.weekday; // 1=seg, 7=dom
      start = DateTime(now.year, now.month, now.day - (weekday - 1));
      end = DateTime(now.year, now.month, now.day + (7 - weekday), 23, 59, 59);
      break;
    case RankingPeriod.thisMonth:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      break;
  }

  // Buscar vendas e membros da equipe
  final futures = await Future.wait([
    financialRepo.fetchSalesWithItems(profile.companyId!, start, end),
    profileRepo.fetchTeamMembers(profile.companyId!),
  ]);

  final sales = futures[0] as List;
  final team = futures[1] as List;

  // Mapa para agregar o faturamento por vendedor
  final revenueMap = <String, int>{};
  for (final sale in sales) {
    final sellerId = sale.sellerId;
    if (sellerId != null && sellerId.isNotEmpty) {
      revenueMap[sellerId] = (revenueMap[sellerId] ?? 0) + (sale.totalAmount as int);
    }
  }

  // Verificar se há alguma meta
  int totalGoals = 0;
  for (final member in team) {
    totalGoals += member.monthlySalesGoal as int;
  }
  final hasGoal = totalGoals > 0;

  // Montar lista de SellerRank
  final ranking = team.map((member) {
    return SellerRank(
      sellerId: member.id,
      sellerName: member.name,
      avatarUrl: member.avatarUrl,
      revenue: revenueMap[member.id] ?? 0,
      goal: member.monthlySalesGoal,
      isOwner: member.isOwner,
    );
  }).toList();

  // Ordenação
  ranking.sort((a, b) {
    if (hasGoal) {
      final diff = b.progressPercentage.compareTo(a.progressPercentage);
      if (diff != 0) return diff;
      return b.revenue.compareTo(a.revenue);
    } else {
      return b.revenue.compareTo(a.revenue);
    }
  });

  return ranking;
});

/// Dados para o gráfico anual de faturamento mensal por vendedor
class MonthlyRevenue {
  final int month; // 1-12
  final int revenue; // centavos
  MonthlyRevenue({required this.month, required this.revenue});
}

/// ID especial para "Todos" no gráfico
const kAllSellersId = '__all__';

final yearlyChartProvider = FutureProvider.autoDispose.family<List<MonthlyRevenue>, String>((ref, sellerId) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null || profile.companyId == null) return [];

  final financialRepo = ref.read(financialRepositoryProvider);
  final now = DateTime.now();

  // Buscar vendas do ano inteiro
  final start = DateTime(now.year, 1, 1);
  final end = DateTime(now.year, 12, 31, 23, 59, 59);

  final sales = await financialRepo.fetchSalesWithItems(profile.companyId!, start, end);

  // Agregar por mês para o vendedor selecionado (ou todos se kAllSellersId)
  final isAll = sellerId == kAllSellersId;
  final monthMap = <int, int>{}; // month -> total centavos
  for (final sale in sales) {
    if ((isAll || sale.sellerId == sellerId) && sale.createdAt != null) {
      final month = sale.createdAt!.month;
      monthMap[month] = (monthMap[month] ?? 0) + sale.totalAmount;
    }
  }

  // Retornar 12 meses (mesmo os zerados)
  return List.generate(12, (i) {
    final m = i + 1;
    return MonthlyRevenue(month: m, revenue: monthMap[m] ?? 0);
  });
});
