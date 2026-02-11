import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final DateTime orderDate;
  final DateTime? dueDate;
  final String status;
  final double totalAmount;
  final String description;
  final List<String> itemTypes;
  final Map<String, dynamic> measurements;
  final bool isRush;
  final String paymentMethod;
  final double laborCost;
  final double materialCost;
  final double overheadCost;
  final double advanceAmount; // Added for FUNC-005
  final Map<String, String> styleAttributes;
  final int syncStatus;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.orderDate,
    this.dueDate,
    required this.status,
    required this.totalAmount,
    required this.description,
    required this.itemTypes,
    required this.measurements,
    this.isRush = false,
    this.paymentMethod = 'cash',
    this.laborCost = 0.0,
    this.materialCost = 0.0,
    this.overheadCost = 0.0,
    this.advanceAmount = 0.0, // Added for FUNC-005 advance management
    this.styleAttributes = const <String, String>{},
    this.syncStatus = 1,
    required this.updatedAt,
  });

  double get profit => totalAmount - (laborCost + materialCost + overheadCost);
  double get balanceDue => totalAmount - advanceAmount;

  factory Order.fromMap(Map<String, dynamic> data, String documentId) {
    List<String> parseItemTypes(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      if (value is String) {
        if (value.startsWith('[') && value.endsWith(']')) {
          try {
            return List<String>.from(json.decode(value));
          } catch (e) {
            return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
        }
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    Map<String, String> parseStyleAttributes(dynamic value) {
      if (value == null) return <String, String>{};
      if (value is Map) return Map<String, String>.from(value);
      if (value is String && value.isNotEmpty) {
        try {
          return Map<String, String>.from(json.decode(value));
        } catch (e) {
          return <String, String>{};
        }
      }
      return <String, String>{};
    }

    return Order(
      id: documentId,
      customerId: data['customer_id'] ?? data['customerId'] ?? '',
      customerName: data['customer_name'] ?? data['customerName'] ?? '',
      orderDate: data['order_date'] != null 
          ? (data['order_date'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(data['order_date']) 
              : (data['order_date'] as Timestamp).toDate())
          : (data['orderDate'] != null 
              ? (data['orderDate'] is int 
                  ? DateTime.fromMillisecondsSinceEpoch(data['orderDate']) 
                  : (data['orderDate'] as Timestamp).toDate())
              : DateTime.now()),
      dueDate: data['due_date'] != null 
          ? (data['due_date'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(data['due_date']) 
              : (data['due_date'] as Timestamp).toDate())
          : (data['dueDate'] != null 
              ? (data['dueDate'] is int 
                  ? DateTime.fromMillisecondsSinceEpoch(data['dueDate']) 
                  : (data['dueDate'] as Timestamp).toDate())
              : null),
      status: data['status'] ?? 'pending',
      totalAmount: ((data['total_amount'] ?? data['totalAmount']) as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      itemTypes: parseItemTypes(data['item_types'] ?? data['itemTypes']),
      measurements: data['measurements'] != null ? Map<String, dynamic>.from(data['measurements']) : <String, dynamic>{}, // Usually updated separately or handled in getOrdersList
      isRush: (data['is_rush'] ?? data['isRush']) == 1 || (data['isRush'] == true),
      paymentMethod: data['payment_method'] ?? data['paymentMethod'] ?? 'cash',
      laborCost: ((data['labor_cost'] ?? data['laborCost']) as num?)?.toDouble() ?? 0.0,
      materialCost: ((data['material_cost'] ?? data['materialCost']) as num?)?.toDouble() ?? 0.0,
      overheadCost: ((data['overhead_cost'] ?? data['overheadCost']) as num?)?.toDouble() ?? 0.0,
      advanceAmount: ((data['advance_amount'] ?? data['advanceAmount']) as num?)?.toDouble() ?? 0.0,
      styleAttributes: parseStyleAttributes(data['style_attributes_json'] ?? data['styleAttributes']),
      syncStatus: (data['sync_status'] ?? data['syncStatus'] as num?)?.toInt() ?? 0,
      updatedAt: data['updated_at'] != null 
          ? (data['updated_at'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(data['updated_at']) 
              : (data['updated_at'] as Timestamp).toDate())
          : (data['updatedAt'] != null 
              ? (data['updatedAt'] is int 
                  ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt']) 
                  : (data['updatedAt'] as Timestamp).toDate())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'order_date': orderDate.millisecondsSinceEpoch,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'status': status,
      'total_amount': totalAmount,
      'description': description,
      'item_types': itemTypes.join(','),
      'measurements': json.encode(measurements),
      'is_rush': isRush ? 1 : 0,
      'payment_method': paymentMethod,
      'labor_cost': laborCost,
      'material_cost': materialCost,
      'overhead_cost': overheadCost,
      'advance_amount': advanceAmount,
      'style_attributes_json': json.encode(styleAttributes),
      'sync_status': syncStatus,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    DateTime? orderDate,
    DateTime? dueDate,
    String? status,
    double? totalAmount,
    String? description,
    List<String>? itemTypes,
    Map<String, dynamic>? measurements,
    bool? isRush,
    String? paymentMethod,
    double? laborCost,
    double? materialCost,
    double? overheadCost,
    double? advanceAmount,
    Map<String, String>? styleAttributes,
    int? syncStatus,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      orderDate: orderDate ?? this.orderDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      description: description ?? this.description,
      itemTypes: itemTypes ?? this.itemTypes,
      measurements: measurements ?? this.measurements,
      isRush: isRush ?? this.isRush,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      laborCost: laborCost ?? this.laborCost,
      materialCost: materialCost ?? this.materialCost,
      overheadCost: overheadCost ?? this.overheadCost,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      styleAttributes: styleAttributes ?? this.styleAttributes,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
