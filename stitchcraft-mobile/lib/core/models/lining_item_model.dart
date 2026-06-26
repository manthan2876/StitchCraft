
class LiningItem {
  final String id;
  final String orderId;
  final String materialType; // COTTON, CREPE, SATIN, TAFETTA
  final String source; // CLIENT_PROVIDED, SHOP_PROVIDED
  final double unitPrice;
  final double quantity; // in meters
  final String notes;
  final int syncStatus;
  final DateTime updatedAt;

  LiningItem({
    required this.id,
    required this.orderId,
    required this.materialType,
    required this.source,
    required this.unitPrice,
    required this.quantity,
    this.notes = '',
    this.syncStatus = 1,
    required this.updatedAt,
  });

  double get totalCost => source == 'SHOP_PROVIDED' ? unitPrice * quantity : 0.0;

  factory LiningItem.fromMap(Map<String, dynamic> data, String documentId) {
    return LiningItem(
      id: documentId,
      orderId: data['order_id'] ?? data['orderId'] ?? '',
      materialType: data['material_type'] ?? data['materialType'] ?? 'COTTON',
      source: data['source'] ?? 'CLIENT_PROVIDED',
      unitPrice: ((data['unit_price'] ?? data['unitPrice'] ?? 0) as num).toDouble(),
      quantity: ((data['quantity'] ?? 0) as num).toDouble(),
      notes: data['notes'] ?? '',
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
      'order_id': orderId,
      'material_type': materialType,
      'source': source,
      'unit_price': unitPrice,
      'quantity': quantity,
      'notes': notes,
      'sync_status': syncStatus,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  LiningItem copyWith({
    String? id,
    String? orderId,
    String? materialType,
    String? source,
    double? unitPrice,
    double? quantity,
    String? notes,
    int? syncStatus,
    DateTime? updatedAt,
  }) {
    return LiningItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      materialType: materialType ?? this.materialType,
      source: source ?? this.source,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get material display name
  String get materialDisplayName {
    switch (materialType) {
      case 'COTTON':
        return 'Cotton Astar';
      case 'CREPE':
        return 'Crepe Astar';
      case 'SATIN':
        return 'Satin Astar';
      case 'TAFETTA':
        return 'Tafetta Astar';
      default:
        return materialType;
    }
  }

  // Helper method to get source display name
  String get sourceDisplayName {
    return source == 'CLIENT_PROVIDED' ? 'Client Provided' : 'Shop Provided';
  }
}
