import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/subscription.dart';
import 'user_profile_provider.dart';

final subscriptionProvider = AsyncNotifierProvider<SubscriptionNotifier, Subscription?>(() {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends AsyncNotifier<Subscription?> {
  @override
  Future<Subscription?> build() async {
    final profile = ref.watch(userProfileProvider).value;
    if (profile == null || profile.companyId == null) return null;

    final client = Supabase.instance.client;
    final data = await client
        .from('subscriptions')
        .select()
        .eq('company_id', profile.companyId!)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return Subscription.fromJson(data);
  }

  /// Atualiza o status após uma compra via RevenueCat
  Future<void> activateSubscription(String plan) async {
    final profile = ref.read(userProfileProvider).value;
    if (profile?.companyId == null) return;

    final client = Supabase.instance.client;
    await client
        .from('subscriptions')
        .update({
          'plan': plan,
          'status': 'active',
          'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'payment_method': 'revenuecat',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('company_id', profile!.companyId!);

    ref.invalidateSelf();
  }
}
