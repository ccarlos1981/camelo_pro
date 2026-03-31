import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(Supabase.instance.client);
});

class CustomersRepository {
  final SupabaseClient _client;
  CustomersRepository(this._client);

  Future<List<Customer>> fetchAll() async {
    final data = await _client
        .from('customers')
        .select()
        .order('name');

    return (data as List).map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> create({
    required String companyId,
    required String name,
    String? phone,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final data = await _client
        .from('customers')
        .insert({
          'company_id': companyId,
          'name': name,
          'phone': phone,
          'notes': notes,
          'created_by': userId,
        })
        .select()
        .single();

    return Customer.fromJson(data);
  }

  Future<void> update(Customer customer) async {
    await _client
        .from('customers')
        .update({
          'name': customer.name,
          'phone': customer.phone,
          'notes': customer.notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', customer.id);
  }

  Future<void> delete(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }
}
