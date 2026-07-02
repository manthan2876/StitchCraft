import 'dart:convert';
import '../utils/parsing_helpers.dart';

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
  // SRS Phase 4: Material Economics
  final String? fabricPhotoUrl;
  final bool astarRequired;
  final String? astarSource; // CLIENT_PROVIDED, SHOP_PROVIDED
  final double astarCost;
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
    this.advanceAmount = 0.0,
    this.styleAttributes = const <String, String>{},
    this.fabricPhotoUrl,
    this.astarRequired = false,
    this.astarSource,
    this.astarCost = 0.0,
    this.syncStatus = 1,
    required this.updatedAt,
  });

  double get profit => totalAmount - (laborCost + materialCost + overheadCost + astarCost);
  double get balanceDue => totalAmount - advanceAmount;
  double get totalCost => laborCost + materialCost + overheadCost + astarCost;

  factory Order.fromMap(Map<String, dynamic> data, String documentId) {
    return Order(
      id: documentId,
      customerId: data['customer_id'] ?? data['customerId'] ?? '',
      customerName: data['customer_name'] ?? data['customerName'] ?? '',
      orderDate: parseDateTime(data['order_date'] ?? data['orderDate']),
      dueDate: parseNullableDateTime(data['due_date'] ?? data['dueDate']),
      status: data['status'] ?? 'pending',
      totalAmount: ((data['total_amount'] ?? data['totalAmount']) as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      itemTypes: parseItemTypes(data['item_types'] ?? data['itemTypes']),
      measurements: data['measurements'] != null ? Map<String, dynamic>.from(data['measurements']) : <String, dynamic>{},
      isRush: (data['is_rush'] ?? data['isRush']) == 1 || (data['isRush'] == true),
      paymentMethod: data['payment_method'] ?? data['paymentMethod'] ?? 'cash',
      laborCost: ((data['labor_cost'] ?? data['laborCost']) as num?)?.toDouble() ?? 0.0,
      materialCost: ((data['material_cost'] ?? data['materialCost']) as num?)?.toDouble() ?? 0.0,
      overheadCost: ((data['overhead_cost'] ?? data['overheadCost']) as num?)?.toDouble() ?? 0.0,
      advanceAmount: ((data['advance_amount'] ?? data['advanceAmount']) as num?)?.toDouble() ?? 0.0,
      styleAttributes: parseStyleAttributes(data['style_attributes_json'] ?? data['styleAttributes']),
      fabricPhotoUrl: data['fabric_photo_url'] ?? data['fabricPhotoUrl'],
      astarRequired: (data['astar_required'] ?? data['astarRequired'] ?? 0) == 1,
      astarSource: data['astar_source'] ?? data['astarSource'],
      astarCost: ((data['astar_cost'] ?? data['astarCost']) as num?)?.toDouble() ?? 0.0,
      syncStatus: (data['sync_status'] ?? data['syncStatus'] as num?)?.toInt() ?? 0,
      updatedAt: parseDateTime(data['updated_at'] ?? data['updatedAt']),
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
      'fabric_photo_url': fabricPhotoUrl,
      'astar_required': astarRequired ? 1 : 0,
      'astar_source': astarSource,
      'astar_cost': astarCost,
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
    String? fabricPhotoUrl,
    bool? astarRequired,
    String? astarSource,
    double? astarCost,
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
      fabricPhotoUrl: fabricPhotoUrl ?? this.fabricPhotoUrl,
      astarRequired: astarRequired ?? this.astarRequired,
      astarSource: astarSource ?? this.astarSource,
      astarCost: astarCost ?? this.astarCost,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
