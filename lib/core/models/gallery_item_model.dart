import 'dart:convert';

class GalleryItem {
  final String id;
  final String imageUrl;
  final List<String> fabricTags; // CHIFFON, SILK, COTTON, GEORGETTE, etc.
  final List<String> garmentTags; // KURTA, BLOUSE, LEHENGA, ANARKALI, etc.
  final String source; // APP_LIBRARY, USER_UPLOAD
  final String? referenceUrl; // Pinterest/Instagram URL
  final String title;
  final String description;
  final int syncStatus;
  final DateTime updatedAt;

  GalleryItem({
    required this.id,
    required this.imageUrl,
    this.fabricTags = const [],
    this.garmentTags = const [],
    this.source = 'USER_UPLOAD',
    this.referenceUrl,
    this.title = '',
    this.description = '',
    this.syncStatus = 1,
    required this.updatedAt,
  });

  factory GalleryItem.fromMap(Map<String, dynamic> data, String documentId) {
    List<String> parseTags(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      if (value is String && value.isNotEmpty) {
        try {
          return List<String>.from(json.decode(value));
        } catch (e) {
          return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      }
      return [];
    }

    return GalleryItem(
      id: documentId,
      imageUrl: data['image_url'] ?? data['imageUrl'] ?? '',
      fabricTags: parseTags(data['fabric_tags'] ?? data['fabricTags']),
      garmentTags: parseTags(data['garment_tags'] ?? data['garmentTags']),
      source: data['source'] ?? 'USER_UPLOAD',
      referenceUrl: data['reference_url'] ?? data['referenceUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      syncStatus: (data['sync_status'] ?? data['syncStatus'] ?? 1) as int,
      updatedAt: data['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updated_at'])
          : (data['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image_url': imageUrl,
      'fabric_tags': fabricTags.join(','),
      'garment_tags': garmentTags.join(','),
      'source': source,
      'reference_url': referenceUrl,
      'title': title,
      'description': description,
      'sync_status': syncStatus,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  GalleryItem copyWith({
    String? id,
    String? imageUrl,
    List<String>? fabricTags,
    List<String>? garmentTags,
    String? source,
    String? referenceUrl,
    String? title,
    String? description,
    int? syncStatus,
    DateTime? updatedAt,
  }) {
    return GalleryItem(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      fabricTags: fabricTags ?? this.fabricTags,
      garmentTags: garmentTags ?? this.garmentTags,
      source: source ?? this.source,
      referenceUrl: referenceUrl ?? this.referenceUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to check if item matches fabric filter
  bool matchesFabricFilter(String fabricType) {
    return fabricTags.any((tag) => tag.toUpperCase() == fabricType.toUpperCase());
  }

  // Helper method to check if item matches garment filter
  bool matchesGarmentFilter(String garmentType) {
    return garmentTags.any((tag) => tag.toUpperCase() == garmentType.toUpperCase());
  }

  // Helper to check if fabric is suitable for structured garments
  bool get isSuitableForStructured {
    final structuredFabrics = ['COTTON', 'LINEN', 'DENIM', 'WOOL'];
    return fabricTags.any((tag) => structuredFabrics.contains(tag.toUpperCase()));
  }

  // Helper to check if fabric is suitable for flowy garments
  bool get isSuitableForFlowy {
    final flowyFabrics = ['CHIFFON', 'GEORGETTE', 'SILK', 'SATIN'];
    return fabricTags.any((tag) => flowyFabrics.contains(tag.toUpperCase()));
  }
}
