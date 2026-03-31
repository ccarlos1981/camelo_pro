import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/customers_repository.dart';

/// Provider que gerencia a lista de clientes do CRM.
final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<Customer>>(
  CustomersNotifier.new,
);

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    return await ref.read(customersRepositoryProvider).fetchAll();
  }

  Future<void> addCustomer({
    required String companyId,
    required String name,
    String? phone,
    String? notes,
  }) async {
    final repo = ref.read(customersRepositoryProvider);
    await repo.create(
      companyId: companyId,
      name: name,
      phone: phone,
      notes: notes,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteCustomer(String id) async {
    await ref.read(customersRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}
