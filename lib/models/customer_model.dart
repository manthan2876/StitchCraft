import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id; // Primary Key
  final String name;
  final String phone;
  final String email;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });

  // Convert Firestore Document to Model (Read)
  factory Customer.fromMap(Map<String, dynamic> data, String documentId) {
    return Customer(
      id: documentId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
    );
  }

  // New: construct directly from a DocumentSnapshot
  factory Customer.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Customer.fromMap(data, doc.id);
  }

  // Convert Model to Map (Create/Update)
  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'email': email};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
