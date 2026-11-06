/* lib/core/services/database/customer_db_extension.dart */
import '../../models/customer_model.dart';
import '../database_service.dart';
import '../../repositories/customer_repository.dart';

extension CustomerDbExtension on DatabaseService {
  Future<String> addCustomer(Customer customer) async {
    final id = customer.id.isEmpty ? uuid.v4() : customer.id;
    await CustomerRepository().createCustomer(
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      customerId: id,
    );
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
    await CustomerRepository().updateCustomer(
      customer.id,
      customer.toMap(),
    );
  }

  Future<void> deleteCustomer(String id) async {
    await CustomerRepository().deleteCustomer(id);
  }

  Future<void> deleteCustomerAndRelatedData(String customerId) async {
    await deleteCustomer(customerId);
  }
}
