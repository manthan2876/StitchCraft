/* lib/core/services/database/order_db_extension.dart */
import 'dart:convert';
import 'dart:developer' as developer;
import '../../models/order_model.dart' as order_model;
import '../database_service.dart';
import '../notification_service.dart';

extension OrderDbExtension on DatabaseService {
  Future<String> addOrder(order_model.Order order) async {
    final id = order.id.isEmpty ? uuid.v4() : order.id;
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
    
    await localDb.insertOrder(map);
    
    if (updatedOrder.dueDate != null) {
      try {
        final reminderDate = updatedOrder.dueDate!.subtract(const Duration(days: 1));
        if (reminderDate.isAfter(DateTime.now())) {
          final seconds = reminderDate.difference(DateTime.now()).inSeconds;
          await NotificationService().scheduleNotification(
            id.hashCode,
            'Order Due Soon',
            'Order for ${updatedOrder.customerName} is due tomorrow!',
            seconds,
          );
        }
      } catch (e) {
        developer.log('Failed to schedule notification: $e', name: 'DatabaseService');
      }
    }

    DatabaseService.orderSignal.add(null);
    return id;
  }

  Stream<List<order_model.Order>> getOrders() async* {
    yield await getOrdersList();
    yield* DatabaseService.orderSignal.stream.asyncMap((_) => getOrdersList());
  }

  Future<List<order_model.Order>> getOrdersList() async {
    final maps = await localDb.getAllOrders();
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
    
    await localDb.insertOrder(map);

    if (updatedOrder.dueDate != null) {
      try {
        final reminderDate = updatedOrder.dueDate!.subtract(const Duration(days: 1));
        if (reminderDate.isAfter(DateTime.now())) {
          final seconds = reminderDate.difference(DateTime.now()).inSeconds;
          await NotificationService().scheduleNotification(
            order.id.hashCode,
            'Order Due Soon',
            'Order for ${updatedOrder.customerName} is due tomorrow!',
            seconds,
          );
        }
      } catch (e) {
        developer.log('Failed to schedule notification: $e', name: 'DatabaseService');
      }
    }

    DatabaseService.orderSignal.add(null);

    // FUNC-007: Update Loyalty Points & LTV on Order Completion
    if (updatedOrder.status == 'Completed' && order.status != 'Completed') {
      await _updateCustomerLoyaltyAndLTV(updatedOrder.customerId, updatedOrder.totalAmount);
    }
  }

  Future<void> _updateCustomerLoyaltyAndLTV(String customerId, double orderAmount) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
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
    yield* DatabaseService.orderSignal.stream.asyncMap((_) => getOrdersListByCustomer(customerId));
  }

  Future<List<order_model.Order>> getOrdersListByCustomer(String customerId) async {
    final maps = await localDb.getAllOrders();
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
    await localDb.updateSyncStatus('orders', id, 2);
    DatabaseService.orderSignal.add(null);
  }
}
