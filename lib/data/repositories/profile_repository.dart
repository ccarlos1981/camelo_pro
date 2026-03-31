import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository(this._client);

  /// Busca o perfil do usuário logado.
  Future<UserProfile?> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  /// Busca todos os funcionários da mesma empresa.
  Future<List<UserProfile>> fetchTeamMembers(String companyId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('company_id', companyId)
        .order('name');

    return (data as List).map((e) => UserProfile.fromJson(e)).toList();
  }

  /// Atualiza permissões de um funcionário.
  Future<void> updatePermissions(String profileId, Map<String, dynamic> permissions) async {
    await _client
        .from('profiles')
        .update({'permissions': permissions})
        .eq('id', profileId);
  }

  /// Atualiza a meta de vendas mensal de um funcionário.
  Future<void> updateSalesGoal(String profileId, int goalInCents) async {
    await _client
        .from('profiles')
        .update({'monthly_sales_goal': goalInCents})
        .eq('id', profileId);
  }

  /// Marca que a senha foi trocada.
  Future<void> clearMustChangePassword(String profileId) async {
    await _client
        .from('profiles')
        .update({'must_change_password': false})
        .eq('id', profileId);
  }

  /// Remove um funcionário da equipe (limpa company_id).
  Future<void> removeFromTeam(String profileId) async {
    await _client
        .from('profiles')
        .update({'company_id': null})
        .eq('id', profileId);
  }

  /// Convida funcionário via Edge Function.
  Future<Map<String, dynamic>> inviteEmployee({
    required String phone,
    required String name,
    Map<String, dynamic>? permissions,
  }) async {
    final response = await _client.functions.invoke(
      'create-employee',
      body: {
        'phone': phone,
        'name': name,
        'permissions': permissions,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Erro desconhecido';
      throw Exception(error);
    }

    return response.data as Map<String, dynamic>;
  }
}
