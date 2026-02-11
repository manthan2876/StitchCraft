import 'dart:async';
import 'dart:convert';
import 'package:stitchcraft/core/models/customer_model.dart';
import 'package:stitchcraft/core/models/order_model.dart' as order_model;
import 'package:stitchcraft/core/models/measurement_model.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  final _localDb = LocalDatabaseService();
  final _uuid = Uuid();

  // Signal Controllers for reactive UI (broadcasters)
  static final _customerSignal = StreamController<void>.broadcast();
  static final _orderSignal = StreamController<void>.broadcast();
  static final _measurementSignal = StreamController<void>.broadcast();

  // ============== CUSTOMER CRUD ==============

  Future<String> addCustomer(Customer customer) async {
    final id = customer.id.isEmpty ? _uuid.v4() : customer.id;
    final updatedCustomer = customer.copyWith(
      id: id,
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );
    await _localDb.insertCustomer(updatedCustomer.toMap()..['id'] = id);
    _customerSignal.add(null);
    return id;
  }

  Stream<List<Customer>> getCustomers() async* {
    yield await getCustomersList();
    yield* _customerSignal.stream.asyncMap((_) => getCustomersList());
  }

  Future<List<Customer>> getCustomersList() async {
    final maps = await _localDb.getCustomers();
    return maps.map((m) => Customer.fromMap(m, m['id'] as String)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final map = await _localDb.getCustomer(id);
    return map != null ? Customer.fromMap(map, map['id'] as String) : null;
  }

  Future<void> updateCustomer(Customer customer) async {
    final updatedCustomer = customer.copyWith(
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );
    await _localDb.insertCustomer(updatedCustomer.toMap()..['id'] = customer.id);
    _customerSignal.add(null);
  }

  Future<void> deleteCustomer(String id) async {
    await _localDb.updateSyncStatus('customers', id, 2); // Mark as deleted
    _customerSignal.add(null);
  }

  Future<void> deleteCustomerAndRelatedData(String customerId) async {
    await deleteCustomer(customerId);
    _customerSignal.add(null);
  }

  // ============== ORDER CRUD ==============

  Future<String> addOrder(order_model.Order order) async {
    final id = order.id.isEmpty ? _uuid.v4() : order.id;
    final updatedOrder = order.copyWith(
      id: id,
      syncStatus: 1,
      updatedAt: DateTime.now(),
      orderDate: order.orderDate,
    );
    
    final Map<String, dynamic> map = {
      'id': id,
      'customer_id': updatedOrder.customerId,
      'customer_name': updatedOrder.customerName,
      'order_date': updatedOrder.orderDate.millisecondsSinceEpoch,
      'due_date': updatedOrder.dueDate?.millisecondsSinceEpoch,
      'status': updatedOrder.status,
      'total_amount': updatedOrder.totalAmount,
      'description': updatedOrder.description,
      'item_types': updatedOrder.itemTypes.join(','),
      'is_rush': updatedOrder.isRush ? 1 : 0,
      'payment_method': updatedOrder.paymentMethod,
      'labor_cost': updatedOrder.laborCost,
      'material_cost': updatedOrder.materialCost,
      'overhead_cost': updatedOrder.overheadCost,
      'style_attributes_json': jsonEncode(updatedOrder.styleAttributes),
      'sync_status': updatedOrder.syncStatus,
      'updated_at': updatedOrder.updatedAt.millisecondsSinceEpoch,
    };
    
    await _localDb.insertOrder(map);
    
    // Schedule notification for due date (1 day before)
    if (updatedOrder.dueDate != null) {
      final reminderDate = updatedOrder.dueDate!.subtract(const Duration(days: 1));
      if (reminderDate.isAfter(DateTime.now())) {
        await NotificationService().scheduleOrderReminder(
          id: id.hashCode,
          title: 'Order Due Soon',
          body: 'Order for ${updatedOrder.customerName} is due tomorrow!',
          scheduledDate: reminderDate,
        );
      }
    }

    _orderSignal.add(null);
    return id;
  }

  Stream<List<order_model.Order>> getOrders() async* {
    yield await getOrdersList();
    yield* _orderSignal.stream.asyncMap((_) => getOrdersList());
  }

  Future<List<order_model.Order>> getOrdersList() async {
    final maps = await _localDb.getAllOrders();
    return maps.map((m) {
        final data = Map<String, dynamic>.from(m);
        data['id'] = m['id'];
        data['customerId'] = m['customer_id'];
        data['customerName'] = m['customer_name'];
        data['orderDate'] = m['order_date'];
        data['dueDate'] = m['due_date'];
        data['status'] = m['status'];
        data['totalAmount'] = m['total_amount'];
        data['description'] = m['description'];
        data['itemTypes'] = (m['item_types'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? <String>[];
        data['measurements'] = <String, dynamic>{}; 
        data['isRush'] = m['is_rush'] == 1;
        data['paymentMethod'] = m['payment_method'];
        data['laborCost'] = m['labor_cost'];
        data['materialCost'] = m['material_cost'];
        data['overheadCost'] = m['overhead_cost'];
        data['styleAttributes'] = m['style_attributes_json'] != null 
            ? Map<String, String>.from(jsonDecode(m['style_attributes_json'])) 
            : <String, String>{};
        data['syncStatus'] = m['sync_status'];
        data['updatedAt'] = m['updated_at'];
        
        return order_model.Order.fromMap(data, m['id'] as String);
    }).toList();
  }

  Future<void> updateOrder(order_model.Order order) async {
    final updatedOrder = order.copyWith(
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );
    
    final Map<String, dynamic> map = {
      'id': order.id,
      'customer_id': updatedOrder.customerId,
      'customer_name': updatedOrder.customerName,
      'order_date': updatedOrder.orderDate.millisecondsSinceEpoch,
      'due_date': updatedOrder.dueDate?.millisecondsSinceEpoch,
      'status': updatedOrder.status,
      'total_amount': updatedOrder.totalAmount,
      'description': updatedOrder.description,
      'item_types': updatedOrder.itemTypes.join(','),
      'is_rush': updatedOrder.isRush ? 1 : 0,
      'payment_method': updatedOrder.paymentMethod,
      'labor_cost': updatedOrder.laborCost,
      'material_cost': updatedOrder.materialCost,
      'overhead_cost': updatedOrder.overheadCost,
      'style_attributes_json': jsonEncode(updatedOrder.styleAttributes),
      'sync_status': updatedOrder.syncStatus,
      'updated_at': updatedOrder.updatedAt.millisecondsSinceEpoch,
    };
    
    await _localDb.insertOrder(map);

    // Update notification for due date
    if (updatedOrder.dueDate != null) {
      final reminderDate = updatedOrder.dueDate!.subtract(const Duration(days: 1));
      if (reminderDate.isAfter(DateTime.now())) {
        await NotificationService().scheduleOrderReminder(
          id: order.id.hashCode,
          title: 'Order Due Soon',
          body: 'Order for ${updatedOrder.customerName} is due tomorrow!',
          scheduledDate: reminderDate,
        );
      }
    }

    _orderSignal.add(null);

    // FUNC-007: Update Loyalty Points & LTV on Order Completion
    if (updatedOrder.status == 'Completed' && order.status != 'Completed') {
      await _updateCustomerLoyaltyAndLTV(updatedOrder.customerId, updatedOrder.totalAmount);
    }
  }

  Future<void> _updateCustomerLoyaltyAndLTV(String customerId, double orderAmount) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      // Logic: 1 Point per ₹100 spent (Example)
      final newPoints = (orderAmount / 100).floor();
      final updatedCustomer = customer.copyWith(
        loyaltyPoints: customer.loyaltyPoints + newPoints,
        ltv: customer.ltv + orderAmount,
        updatedAt: DateTime.now(),
      );
      await updateCustomer(updatedCustomer);
    }
  }

  Stream<List<order_model.Order>> getOrdersByCustomerId(String customerId) async* {
    yield await getOrdersListByCustomer(customerId);
    yield* _orderSignal.stream.asyncMap((_) => getOrdersListByCustomer(customerId));
  }

  Future<List<order_model.Order>> getOrdersListByCustomer(String customerId) async {
    final maps = await _localDb.getAllOrders(); // We could optimize this with a filter in local_db
    return maps
        .where((m) => m['customer_id'] == customerId)
        .map((m) {
            final data = Map<String, dynamic>.from(m);
            data['id'] = m['id'];
            data['customerId'] = m['customer_id'];
            data['customerName'] = m['customer_name'];
            data['orderDate'] = m['order_date'];
            data['dueDate'] = m['due_date'];
            data['status'] = m['status'];
            data['totalAmount'] = m['total_amount'];
            data['description'] = m['description'];
            data['itemTypes'] = (m['item_types'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? <String>[];
            data['measurements'] = <String, dynamic>{}; 
            data['isRush'] = m['is_rush'] == 1;
            data['paymentMethod'] = m['payment_method'];
            data['laborCost'] = m['labor_cost'];
            data['materialCost'] = m['material_cost'];
            data['overheadCost'] = m['overhead_cost'];
            data['styleAttributes'] = m['style_attributes_json'] != null 
                ? Map<String, String>.from(jsonDecode(m['style_attributes_json'])) 
                : <String, String>{};
            data['syncStatus'] = m['sync_status'];
            data['updatedAt'] = m['updated_at'];
            
            return order_model.Order.fromMap(data, m['id'] as String);
        }).toList();
  }

  Future<void> deleteOrder(String id) async {
    await _localDb.updateSyncStatus('orders', id, 2);
    _orderSignal.add(null);
  }

  // ============== MEASUREMENT CRUD ==============

  Future<String> addMeasurement(Measurement measurement) async {
    final id = measurement.id.isEmpty ? _uuid.v4() : measurement.id;
    final updatedMeasurement = measurement.copyWith(
      id: id,
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );
    
    final map = updatedMeasurement.toMap()..['id'] = id;
    await _localDb.insertMeasurement(map);
    _measurementSignal.add(null);
    return id;
  }

  Stream<List<Measurement>> getMeasurements() async* {
    yield await getMeasurementsList();
    yield* _measurementSignal.stream.asyncMap((_) => getMeasurementsList());
  }

  Future<List<Measurement>> getMeasurementsList() async {
    final maps = await _localDb.getUnsyncedRecords('measurements'); // Using helper or need better query
    // Actually need a specific query for all measurements in local_db_service
    return maps.map((m) => Measurement.fromMap(m, m['id'] as String)).toList();
  }

  Stream<List<Measurement>> getMeasurementsByCustomerId(String customerId) async* {
    yield await getMeasurementsListByCustomer(customerId);
    yield* _measurementSignal.stream.asyncMap((_) => getMeasurementsListByCustomer(customerId));
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    final updatedMeasurement = measurement.copyWith(
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );
    await _localDb.insertMeasurement(updatedMeasurement.toMap()..['id'] = measurement.id);
    _measurementSignal.add(null);
  }

  Future<void> deleteMeasurement(String id) async {
    await _localDb.updateSyncStatus('measurements', id, 2);
    _measurementSignal.add(null);
  }

    final maps = await _localDb.getMeasurementsByCustomer(customerId);
    return maps.map((m) => Measurement.fromMap(m, m['id'] as String)).toList();
  }

  // ============== EXPENSE CRUD ==============
  static final _expenseSignal = StreamController<void>.broadcast();

  Future<void> addExpense(String category, double amount, String description, DateTime date) async {
    final id = _uuid.v4();
    final map = {
      'id': id,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'sync_status': 1,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    await _localDb.insertExpense(map);
    _expenseSignal.add(null);
  }

  Stream<List<Map<String, dynamic>>> getExpenses() async* {
    yield await getExpensesList();
    yield* _expenseSignal.stream.asyncMap((_) => getExpensesList());
  }

  Future<List<Map<String, dynamic>>> getExpensesList() async {
    return await _localDb.getAllExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _localDb.deleteExpense(id);
    _expenseSignal.add(null);
  }

  // ============== PROFITABILITY ANALYTICS ==============
  Future<Map<String, double>> getFinancialSummary() async {
    final orders = await getOrdersList();
    final expenses = await getExpensesList();

    double totalRevenue = 0;
    double totalCOGS = 0; // Labor + Material
    double totalOverhead = 0; // Assigned overheads
    double totalExpenses = 0; // OPEX from expense table

    for (var o in orders) {
       // Only count revenue for active/completed orders, not cancelled? 
       // For now, count all non-cancelled. assuming status != 'Cancelled'
       if (o.status != 'Cancelled') {
         totalRevenue += o.totalAmount;
         totalCOGS += (o.laborCost + o.materialCost);
         totalOverhead += o.overheadCost;
       }
    }

    for (var e in expenses) {
      totalExpenses += (e['amount'] as num).toDouble();
    }

    return {
      'revenue': totalRevenue,
      'cogs': totalCOGS,
      'gross_profit': totalRevenue - totalCOGS,
      'expenses': totalExpenses,
      'net_profit': totalRevenue - totalCOGS - totalExpenses - totalOverhead
    };
  }
}
