class SellerRank {
  final String sellerId;
  final String sellerName;
  final String? avatarUrl;
  final int revenue; // em centavos
  final int goal;    // em centavos
  final bool isOwner; // para diferenciar dono/vendedor

  const SellerRank({
    required this.sellerId,
    required this.sellerName,
    this.avatarUrl,
    required this.revenue,
    required this.goal,
    this.isOwner = false,
  });

  /// Percentual de progresso em relação à meta (ex: 0.75 para 75%).
  /// Se a meta for 0, retorna 0.0.
  double get progressPercentage {
    if (goal <= 0) return 0.0;
    return revenue / goal;
  }

  /// Retorna o percentual formatado, garantindo que não ultrapasse 100% de representação se desejado,
  /// ou retornando valores como 120% caso tenha batido a meta com folga.
  String get formattedPercentage {
    if (goal <= 0) return 'Sem meta';
    return '${(progressPercentage * 100).toStringAsFixed(1)}%';
  }
}
