import 'user_permissions.dart';

/// Modelo do perfil do usuário logado.
/// Corresponde à tabela `profiles` no Supabase.
class UserProfile {
  final String id;
  final String? companyId;
  final String name;
  final String? email;
  final String? phone;
  final String role; // 'ADMIN_EMPRESA' ou 'FUNCIONARIO'
  final String? avatarUrl;
  final UserPermissions permissions;
  final bool mustChangePassword;
  final int monthlySalesGoal;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    this.companyId,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.permissions = const UserPermissions(),
    this.mustChangePassword = false,
    this.monthlySalesGoal = 0,
    this.createdAt,
  });

  bool get isOwner => role == 'ADMIN_EMPRESA';
  bool get isEmployee => role == 'FUNCIONARIO';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      name: json['name'] as String? ?? 'Usuário',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'FUNCIONARIO',
      avatarUrl: json['avatar_url'] as String?,
      permissions: UserPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>?,
      ),
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      monthlySalesGoal: json['monthly_sales_goal'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  UserProfile copyWith({
    String? name,
    String? phone,
    UserPermissions? permissions,
    bool? mustChangePassword,
    int? monthlySalesGoal,
  }) {
    return UserProfile(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      avatarUrl: avatarUrl,
      permissions: permissions ?? this.permissions,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      monthlySalesGoal: monthlySalesGoal ?? this.monthlySalesGoal,
      createdAt: createdAt,
    );
  }
}
