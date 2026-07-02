/* lib/core/utils/parsing_helpers.dart */
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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

DateTime parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

DateTime? parseNullableDateTime(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
