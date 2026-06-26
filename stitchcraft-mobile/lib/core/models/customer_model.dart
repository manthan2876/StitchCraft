import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String gender; // Added
  final String? photoUri;
  final Map<String, dynamic> physicalAttributes;
  final Map<String, dynamic> softPreferences;
  final double rating;
  final int loyaltyPoints;
  final double ltv;
  final int syncStatus;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.gender = 'Male', // Default
    this.photoUri,
    this.physicalAttributes = const <String, dynamic>{},
    this.softPreferences = const <String, dynamic>{},
    this.rating = 0.0,
    this.loyaltyPoints = 0,
    this.ltv = 0.0,
    this.syncStatus = 1,
    required this.updatedAt,
  });

  factory Customer.fromMap(Map<String, dynamic> data, String documentId) {
    Map<String, dynamic> parseJsonMap(dynamic value) {
      if (value == null) return <String, dynamic>{};
      if (value is Map<String, dynamic>) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return Map<String, dynamic>.from(json.decode(value));
        } catch (e) {
          return <String, dynamic>{};
        }
      }
      return <String, dynamic>{};
    }

    return Customer(
      id: documentId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? 'Male',
      photoUri: data['photo_uri'],
      physicalAttributes: parseJsonMap(data['physical_attributes']),
      softPreferences: parseJsonMap(data['soft_preferences']),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      loyaltyPoints: data['loyalty_points'] ?? 0,
      ltv: (data['ltv'] as num?)?.toDouble() ?? 0.0,
      syncStatus: data['sync_status'] ?? 0,
      updatedAt: data['updated_at'] != null 
          ? (data['updated_at'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(data['updated_at']) 
              : (data['updated_at'] as Timestamp).toDate())
          : DateTime.now(),
    );
  }

  factory Customer.fromSnapshot(DocumentSnapshot doc) {
    return Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'gender': gender,
      'photo_uri': photoUri,
      'physical_attributes': json.encode(physicalAttributes),
      'soft_preferences': json.encode(softPreferences),
      'rating': rating,
      'loyalty_points': loyaltyPoints,
      'ltv': ltv,
      'sync_status': syncStatus,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? gender,
    String? photoUri,
    Map<String, dynamic>? physicalAttributes,
    Map<String, dynamic>? softPreferences,
    double? rating,
    int? loyaltyPoints,
    double? ltv,
    int? syncStatus,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      photoUri: photoUri ?? this.photoUri,
      physicalAttributes: physicalAttributes ?? this.physicalAttributes,
      softPreferences: softPreferences ?? this.softPreferences,
      rating: rating ?? this.rating,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      ltv: ltv ?? this.ltv,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
