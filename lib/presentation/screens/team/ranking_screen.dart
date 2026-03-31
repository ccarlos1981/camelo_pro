import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/seller_rank.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../providers/ranking_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../../data/models/product.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  String? _selectedSellerId;
  bool _showChart = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rankingAsync = ref.watch(rankingProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currentPeriod = ref.watch(rankingPeriodProvider);

    final isOwner = profileAsync.value?.isOwner == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de Vendas'),
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.leaderboard_rounded : Icons.bar_chart_rounded),
            tooltip: _showChart ? 'Ver Ranking' : 'Ver Gráfico Anual',
            onPressed: () {
              setState(() => _showChart = !_showChart);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros de período
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: RankingPeriod.values.map((period) {
                final isSelected = period == currentPeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getPeriodLabel(period)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) ref.read(rankingPeriodProvider.notifier).setPeriod(period);
                    },
                    selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),

          // Conteúdo principal
          Expanded(
            child: _showChart
                ? _buildChartView(theme, colorScheme, rankingAsync)
                : _buildRankingView(theme, colorScheme, rankingAsync, isOwner),
          ),
        ],
      ),
    );
  }

  /// View do Ranking
  Widget _buildRankingView(ThemeData theme, ColorScheme colorScheme, AsyncValue<List<SellerRank>> rankingAsync, bool isOwner) {
    return rankingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro: $err')),
      data: (ranking) {
        if (ranking.isEmpty) {
          return const Center(child: Text('Nenhum dado encontrado.'));
        }

        int totalRevenue = 0;
        int totalGoal = 0;
        for (final r in ranking) {
          totalRevenue += r.revenue;
          totalGoal += r.goal;
        }
        final hasGoal = totalGoal > 0;
        final pct = hasGoal ? (totalRevenue / totalGoal) : 0.0;

        return Column(
          children: [
            // Header de totais
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
              ),
              child: Column(
                children: [
                  Text(
                    _getPeriodLabel(ref.watch(rankingPeriodProvider)),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${Product.centsToReal(totalRevenue)}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (hasGoal) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        pct >= 1.0 ? Colors.green : colorScheme.primary,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(pct * 100).toStringAsFixed(1)}% alcançado', style: theme.textTheme.bodySmall),
                        Text('Meta: R\$ ${Product.centsToReal(totalGoal)}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text('Sem meta definida', style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    )),
                  ],
                ],
              ),
            ),

            // Lista ranking
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: ranking.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final rank = ranking[index];
                  return _RankingCard(
                    rank: rank,
                    position: index + 1,
                    isOwner: isOwner,
                    hasGlobalGoal: hasGoal,
                    onTapEditGoal: () {
                      if (isOwner) _showEditGoalModal(context, ref, rank);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// View do Gráfico Anual
  Widget _buildChartView(ThemeData theme, ColorScheme colorScheme, AsyncValue<List<SellerRank>> rankingAsync) {
    return rankingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro: $err')),
      data: (ranking) {
        if (ranking.isEmpty) {
          return const Center(child: Text('Nenhum vendedor cadastrado.'));
        }

        // Seleciona o primeiro vendedor por padrão (se nulo, agora pega 'Todos')
        _selectedSellerId ??= kAllSellersId;

        // Criar item fictício para 'Todos'
        final allItem = SellerRank(
          sellerId: kAllSellersId,
          sellerName: 'Todos (Geral)',
          revenue: 0,
          goal: 0,
          isOwner: false,
          avatarUrl: null,
        );
        
        // Incluir 'Todos' no início da lista
        final chartOptions = [allItem, ...ranking];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seletor de vendedor
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Faturamento Anual ${DateTime.now().year}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: chartOptions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final seller = chartOptions[i];
                        final isSelected = seller.sellerId == _selectedSellerId;
                        final isAll = seller.sellerId == kAllSellersId;
                        
                        return ChoiceChip(
                          avatar: isAll 
                            ? Icon(Icons.storefront_rounded, size: 16, color: colorScheme.primary)
                            : CircleAvatar(
                                radius: 12,
                                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                                child: Text(
                                  seller.sellerName.isNotEmpty ? seller.sellerName[0].toUpperCase() : '?',
                                  style: TextStyle(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                          label: Text(isAll ? 'Todos' : seller.sellerName.split(' ').first),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedSellerId = seller.sellerId);
                          },
                          selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Gráfico de barras
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final chartAsync = ref.watch(yearlyChartProvider(_selectedSellerId!));
                  return chartAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Erro: $err')),
                    data: (months) {
                      final maxRevenue = months.fold<int>(0, (max, m) => m.revenue > max ? m.revenue : max);
                      final selectedName = _selectedSellerId == kAllSellersId 
                          ? 'Geral' 
                          : ranking
                              .firstWhere((r) => r.sellerId == _selectedSellerId,
                                  orElse: () => ranking.first)
                              .sellerName
                              .split(' ')
                              .first;

                      // Total anual
                      final yearTotal = months.fold<int>(0, (sum, m) => sum + m.revenue);

                      return Column(
                        children: [
                          // Total anual do vendedor
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total $selectedName em ${DateTime.now().year}',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  Text('R\$ ${Product.centsToReal(yearTotal)}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF10B981),
                                    )),
                                ],
                              ),
                            ),
                          ),

                          // Gráfico
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: _BarChart(
                                months: months,
                                maxRevenue: maxRevenue,
                                primaryColor: colorScheme.primary,
                                theme: theme,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _getPeriodLabel(RankingPeriod period) {
    switch (period) {
      case RankingPeriod.today: return 'Hoje';
      case RankingPeriod.thisWeek: return 'Esta Semana';
      case RankingPeriod.thisMonth: return 'Este Mês';
    }
  }

  void _showEditGoalModal(BuildContext context, WidgetRef ref, SellerRank rank) {
    final theme = Theme.of(context);
    final ctrl = TextEditingController(text: (rank.goal / 100).toStringAsFixed(2));
    var isLoading = false;

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
                Text('Meta de ${rank.sellerName}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Meta Mensal (R\$)',
                    prefixText: 'R\$ ',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final val = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0;
                            final cents = (val * 100).toInt();
                            setModalState(() => isLoading = true);
                            try {
                              await ref.read(profileRepositoryProvider).updateSalesGoal(rank.sellerId, cents);
                              ref.invalidate(rankingProvider);
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
                        : const Text('Salvar Meta'),
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

// ── Gráfico de Barras (Custom Paint) ──

class _BarChart extends StatelessWidget {
  final List<MonthlyRevenue> months;
  final int maxRevenue;
  final Color primaryColor;
  final ThemeData theme;

  const _BarChart({
    required this.months,
    required this.maxRevenue,
    required this.primaryColor,
    required this.theme,
  });

  static const _monthLabels = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight - 40; // Espaço para labels
        final barWidth = (constraints.maxWidth - 24) / 12 - 6;

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(12, (i) {
                  final month = months[i];
                  final height = maxRevenue > 0
                      ? (month.revenue / maxRevenue) * (availableHeight - 20)
                      : 0.0;
                  final isCurrent = (i + 1) == currentMonth;
                  final hasRevenue = month.revenue > 0;

                  return Tooltip(
                    message: 'R\$ ${Product.centsToReal(month.revenue)}',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasRevenue)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _shortValue(month.revenue),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? primaryColor : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          width: barWidth.clamp(12, 28),
                          height: height.clamp(hasRevenue ? 4.0 : 2.0, availableHeight - 20),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? primaryColor
                                : hasRevenue
                                    ? primaryColor.withValues(alpha: 0.5)
                                    : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(12, (i) {
                final isCurrent = (i + 1) == currentMonth;
                return SizedBox(
                  width: barWidth.clamp(12, 28) + 6,
                  child: Text(
                    _monthLabels[i],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? primaryColor : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  String _shortValue(int cents) {
    final reais = cents / 100;
    if (reais >= 1000) {
      return '${(reais / 1000).toStringAsFixed(1)}k';
    }
    return reais.toStringAsFixed(0);
  }
}

// ── Card do Ranking ──

class _RankingCard extends StatelessWidget {
  final SellerRank rank;
  final int position;
  final bool isOwner;
  final bool hasGlobalGoal;
  final VoidCallback onTapEditGoal;

  const _RankingCard({
    required this.rank,
    required this.position,
    required this.isOwner,
    required this.hasGlobalGoal,
    required this.onTapEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget badge;

    if (position == 1 && rank.revenue > 0) {
      badge = const Text('🥇', style: TextStyle(fontSize: 24));
    } else if (position == 2 && rank.revenue > 0) {
      badge = const Text('🥈', style: TextStyle(fontSize: 24));
    } else if (position == 3 && rank.revenue > 0) {
      badge = const Text('🥉', style: TextStyle(fontSize: 24));
    } else {
      badge = CircleAvatar(
        radius: 14,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Text(
          '$positionº',
          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      );
    }

    final bool hasOwnGoal = rank.goal > 0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isOwner ? onTapEditGoal : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  badge,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rank.sellerName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: position <= 3 ? FontWeight.bold : FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (rank.isOwner) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Dono', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontSize: 10)),
                              ),
                            ]
                          ],
                        ),
                        if (isOwner && !hasOwnGoal)
                          Text('Toque para definir meta', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R\$ ${Product.centsToReal(rank.revenue)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: position == 1 && rank.revenue > 0 ? Colors.green : null,
                        ),
                      ),
                      if (hasGlobalGoal && hasOwnGoal)
                        Text(
                          'Meta: R\$ ${Product.centsToReal(rank.goal)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (hasOwnGoal) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: rank.progressPercentage.clamp(0.0, 1.0),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    rank.progressPercentage >= 1.0 ? Colors.green : theme.colorScheme.primary,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    rank.formattedPercentage,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: rank.progressPercentage >= 1.0 ? Colors.green : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
