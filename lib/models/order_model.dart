import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final DateTime orderDate;
  final DateTime? dueDate;
  final String status; // 'pending', 'in_progress', 'completed', 'delivered'
  final double totalAmount;
  final String description;
  final List<String> itemTypes; // Types of items being stitched
  final Map<String, dynamic> measurements; // Reference to measurement details

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
  });

  // Convert Firestore Document to Model (Read)
  factory Order.fromMap(Map<String, dynamic> data, String documentId) {
    return Order(
      id: documentId,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pending',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      itemTypes: List<String>.from(data['itemTypes'] ?? []),
      measurements: data['measurements'] ?? {},
    );
  }

  // Convert Model to Map (Create/Update)
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'orderDate': Timestamp.fromDate(orderDate),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
      'totalAmount': totalAmount,
      'description': description,
      'itemTypes': itemTypes,
      'measurements': measurements,
    };
  }

  // Create a copy with modified fields
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
    );
  }

  // Equality and hashCode for comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
