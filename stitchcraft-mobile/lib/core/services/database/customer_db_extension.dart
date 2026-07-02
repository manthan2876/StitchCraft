/* lib/core/services/database/customer_db_extension.dart */
import '../../models/customer_model.dart';
import '../database_service.dart';

extension CustomerDbExtension on DatabaseService {
  Future<String> addCustomer(Customer customer) async {
    final id = customer.id.isEmpty ? uuid.v4() : customer.id;
    final updatedCustomer = customer.copyWith(
      id: id,
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );
    await localDb.insertCustomer(updatedCustomer.toMap()..['id'] = id);
    DatabaseService.customerSignal.add(null);
    return id;
  }

  Stream<List<Customer>> getCustomers() async* {
    yield await getCustomersList();
    yield* DatabaseService.customerSignal.stream.asyncMap((_) => getCustomersList());
  }

  Future<List<Customer>> getCustomersList() async {
    final maps = await localDb.getCustomers();
    return maps.map((m) => Customer.fromMap(m, m['id'] as String)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final map = await localDb.getCustomer(id);
    return map != null ? Customer.fromMap(map, map['id'] as String) : null;
  }

  Future<void> updateCustomer(Customer customer) async {
    final updatedCustomer = customer.copyWith(
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );
    await localDb.insertCustomer(updatedCustomer.toMap()..['id'] = customer.id);
    DatabaseService.customerSignal.add(null);
  }

  Future<void> deleteCustomer(String id) async {
    await localDb.updateSyncStatus('customers', id, 2);
    DatabaseService.customerSignal.add(null);
  }

  Future<void> deleteCustomerAndRelatedData(String customerId) async {
    await deleteCustomer(customerId);
    DatabaseService.customerSignal.add(null);
  }
}
