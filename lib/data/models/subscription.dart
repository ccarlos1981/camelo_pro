/// Modelo de assinatura da empresa.
/// Espelha a tabela `subscriptions` no Supabase.
class Subscription {
  final String id;
  final String companyId;
  final String plan; // 'trial', 'pro_monthly', 'pro_yearly'
  final DateTime startedAt;
  final DateTime expiresAt;
  final String? paymentMethod;
  final String status; // 'active', 'expired', 'cancelled'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.id,
    required this.companyId,
    required this.plan,
    required this.startedAt,
    required this.expiresAt,
    this.paymentMethod,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// Dias restantes do trial/assinatura
  int get daysRemaining {
    final now = DateTime.now();
    final diff = expiresAt.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Assinatura/trial ainda não expirou?
  bool get isActive => status == 'active' && DateTime.now().isBefore(expiresAt);

  /// Trial expirou ou status é 'expired'?
  bool get isExpired => !isActive;

  /// É trial (gratuito)?
  bool get isTrial => plan == 'trial';

  /// É plano pago?
  bool get isPaid => plan.startsWith('pro_');

  /// Trial está nos últimos 7 dias?
  bool get isTrialUrgent => isTrial && isActive && daysRemaining <= 7;

  /// Label amigável do plano
  String get planLabel {
    switch (plan) {
      case 'trial':
        return 'Teste Grátis';
      case 'pro_monthly':
        return 'Camelo Pro (Mensal)';
      case 'pro_yearly':
        return 'Camelo Pro (Anual)';
      default:
        return plan;
    }
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      plan: json['plan'] as String? ?? 'trial',
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      paymentMethod: json['payment_method'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
