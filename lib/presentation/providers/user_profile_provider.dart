import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';

/// Provider que carrega e mantém o perfil do usuário logado.
/// Usado para determinar o role (ADMIN_EMPRESA vs FUNCIONARIO)
/// e as permissões de acesso.
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    return await ref.read(profileRepositoryProvider).fetchCurrentProfile();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(
      await ref.read(profileRepositoryProvider).fetchCurrentProfile(),
    );
  }

  Future<void> clearMustChangePassword() async {
    final profile = state.value;
    if (profile == null) return;
    await ref.read(profileRepositoryProvider).clearMustChangePassword(profile.id);
    state = AsyncValue.data(profile.copyWith(mustChangePassword: false));
  }
}
