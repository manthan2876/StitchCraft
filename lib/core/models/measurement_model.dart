import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Measurement {
  final String id;
  final String customerId;
  final String orderId;
  final String itemType;
  final Map<String, double> measurements;
  final DateTime measurementDate;
  final String notes;
  final int syncStatus;
  final DateTime updatedAt;

  Measurement({
    required this.id,
    required this.customerId,
    required this.orderId,
    required this.itemType,
    required this.measurements,
    required this.measurementDate,
    required this.notes,
    this.syncStatus = 1,
    required this.updatedAt,
  });

  factory Measurement.fromMap(Map<String, dynamic> data, String documentId) {
    Map<String, double> parseMeasurements(dynamic value) {
      if (value == null) return <String, double>{};
      if (value is Map) {
        return value.map((key, val) => MapEntry(key.toString(), (val as num).toDouble()));
      }
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = json.decode(value) as Map;
          return decoded.map((key, val) => MapEntry(key.toString(), (val as num).toDouble()));
        } catch (e) {
          return <String, double>{};
        }
      }
      return <String, double>{};
    }

    return Measurement(
      id: documentId,
      customerId: data['customer_id'] ?? data['customerId'] ?? '',
      orderId: data['order_id'] ?? data['orderId'] ?? '',
      itemType: data['item_type'] ?? data['itemType'] ?? '',
      measurements: parseMeasurements(data['measurements_json'] ?? data['measurements']),
      notes: data['notes'] ?? '',
      measurementDate: data['measurement_date'] != null 
          ? (data['measurement_date'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(data['measurement_date']) 
              : (data['measurement_date'] as Timestamp).toDate())
          : (data['measurementDate'] != null 
              ? (data['measurementDate'] is int 
                  ? DateTime.fromMillisecondsSinceEpoch(data['measurementDate']) 
                  : (data['measurementDate'] as Timestamp).toDate())
              : DateTime.now()),
      syncStatus: data['sync_status'] ?? data['syncStatus'] ?? 0,
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
      'order_id': orderId,
      'item_type': itemType,
      'measurements_json': json.encode(measurements),
      'measurement_date': measurementDate.millisecondsSinceEpoch,
      'notes': notes,
      'sync_status': syncStatus,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Measurement copyWith({
    String? id,
    String? customerId,
    String? orderId,
    String? itemType,
    Map<String, double>? measurements,
    DateTime? measurementDate,
    String? notes,
    int? syncStatus,
    DateTime? updatedAt,
  }) {
    return Measurement(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      orderId: orderId ?? this.orderId,
      itemType: itemType ?? this.itemType,
      measurements: measurements ?? this.measurements,
      measurementDate: measurementDate ?? this.measurementDate,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
