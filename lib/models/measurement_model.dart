import 'package:cloud_firestore/cloud_firestore.dart';

class Measurement {
  final String id;
  final String customerId;
  final String orderId;
  final String itemType; // e.g., 'shirt', 'pants', 'dress'
  final Map<String, double>
  measurements; // Dynamic measurements like bust, waist, etc.
  final DateTime measurementDate;
  final String notes;

  Measurement({
    required this.id,
    required this.customerId,
    required this.orderId,
    required this.itemType,
    required this.measurements,
    required this.measurementDate,
    required this.notes,
  });

  // Convert Firestore Document to Model (Read)
  factory Measurement.fromMap(Map<String, dynamic> data, String documentId) {
    Map<String, double> parsedMeasurements = {};
    if (data['measurements'] is Map) {
      (data['measurements'] as Map).forEach((key, value) {
        if (value is num) {
          parsedMeasurements[key] = value.toDouble();
        }
      });
    }

    return Measurement(
      id: documentId,
      customerId: data['customerId'] ?? '',
      orderId: data['orderId'] ?? '',
      itemType: data['itemType'] ?? '',
      measurements: parsedMeasurements,
      measurementDate: (data['measurementDate'] as Timestamp).toDate(),
      notes: data['notes'] ?? '',
    );
  }

  // Construct directly from a DocumentSnapshot
  factory Measurement.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Measurement.fromMap(data, doc.id);
  }

  // Convert Model to Map (Create/Update)
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'orderId': orderId,
      'itemType': itemType,
      'measurements': measurements,
      'measurementDate': Timestamp.fromDate(measurementDate),
      'notes': notes,
    };
  }

  // Create a copy with modified fields
  Measurement copyWith({
    String? id,
    String? customerId,
    String? orderId,
    String? itemType,
    Map<String, double>? measurements,
    DateTime? measurementDate,
    String? notes,
  }) {
    return Measurement(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      orderId: orderId ?? this.orderId,
      itemType: itemType ?? this.itemType,
      measurements: measurements ?? this.measurements,
      measurementDate: measurementDate ?? this.measurementDate,
      notes: notes ?? this.notes,
    );
  }

  // Equality and hashCode for comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Measurement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
