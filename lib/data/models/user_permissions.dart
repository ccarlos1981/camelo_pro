/// Modelo tipado para as permissões de um funcionário.
/// Correspondente ao campo JSONB `profiles.permissions`.
class UserPermissions {
  final bool canManageProducts;
  final bool canRegisterSales;
  final bool canViewReports;
  final bool canViewExpenses;
  final bool canManageCustomers;
  final bool canSharePromotions;

  const UserPermissions({
    this.canManageProducts = false,
    this.canRegisterSales = true,
    this.canViewReports = false,
    this.canViewExpenses = false,
    this.canManageCustomers = true,
    this.canSharePromotions = true,
  });

  /// Default para novos funcionários.
  static const defaultEmployee = UserPermissions();

  /// Dono tem todas as permissões.
  static const owner = UserPermissions(
    canManageProducts: true,
    canRegisterSales: true,
    canViewReports: true,
    canViewExpenses: true,
    canManageCustomers: true,
    canSharePromotions: true,
  );

  factory UserPermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPermissions();
    return UserPermissions(
      canManageProducts: json['can_manage_products'] as bool? ?? false,
      canRegisterSales: json['can_register_sales'] as bool? ?? true,
      canViewReports: json['can_view_reports'] as bool? ?? false,
      canViewExpenses: json['can_view_expenses'] as bool? ?? false,
      canManageCustomers: json['can_manage_customers'] as bool? ?? true,
      canSharePromotions: json['can_share_promotions'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'can_manage_products': canManageProducts,
    'can_register_sales': canRegisterSales,
    'can_view_reports': canViewReports,
    'can_view_expenses': canViewExpenses,
    'can_manage_customers': canManageCustomers,
    'can_share_promotions': canSharePromotions,
  };

  UserPermissions copyWith({
    bool? canManageProducts,
    bool? canRegisterSales,
    bool? canViewReports,
    bool? canViewExpenses,
    bool? canManageCustomers,
    bool? canSharePromotions,
  }) {
    return UserPermissions(
      canManageProducts: canManageProducts ?? this.canManageProducts,
      canRegisterSales: canRegisterSales ?? this.canRegisterSales,
      canViewReports: canViewReports ?? this.canViewReports,
      canViewExpenses: canViewExpenses ?? this.canViewExpenses,
      canManageCustomers: canManageCustomers ?? this.canManageCustomers,
      canSharePromotions: canSharePromotions ?? this.canSharePromotions,
    );
  }
}
