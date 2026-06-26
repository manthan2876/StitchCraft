class RepairJob {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String serviceType; // ZIPPER, HEM, PATCH, PICO, FITTING
  final String complexity; // SIMPLE, MEDIUM, COMPLEX
  final String? defectPhotoUrl;
  final double price;
  final String status; // pending, completed, delivered
  final DateTime createdDate;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String notes;
  final int syncStatus;
  final DateTime updatedAt;

  RepairJob({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.serviceType,
    this.complexity = 'SIMPLE',
    this.defectPhotoUrl,
    required this.price,
    this.status = 'pending',
    required this.createdDate,
    this.dueDate,
    this.completedDate,
    this.notes = '',
    this.syncStatus = 1,
    required this.updatedAt,
  });

  factory RepairJob.fromMap(Map<String, dynamic> data, String documentId) {
    return RepairJob(
      id: documentId,
      customerId: data['customer_id'] ?? data['customerId'] ?? '',
      customerName: data['customer_name'] ?? data['customerName'] ?? '',
      customerPhone: data['customer_phone'] ?? data['customerPhone'] ?? '',
      serviceType: data['service_type'] ?? data['serviceType'] ?? 'HEM',
      complexity: data['complexity'] ?? 'SIMPLE',
      defectPhotoUrl: data['defect_photo_url'] ?? data['defectPhotoUrl'],
      price: ((data['price'] ?? 0) as num).toDouble(),
      status: data['status'] ?? 'pending',
      createdDate: data['created_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['created_date'])
          : (data['createdDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['createdDate'])
              : DateTime.now()),
      dueDate: data['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['due_date'])
          : (data['dueDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['dueDate'])
              : null),
      completedDate: data['completed_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['completed_date'])
          : (data['completedDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['completedDate'])
              : null),
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
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'service_type': serviceType,
      'complexity': complexity,
      'defect_photo_url': defectPhotoUrl,
      'price': price,
      'status': status,
      'created_date': createdDate.millisecondsSinceEpoch,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'completed_date': completedDate?.millisecondsSinceEpoch,
      'notes': notes,
      'sync_status': syncStatus,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  RepairJob copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? serviceType,
    String? complexity,
    String? defectPhotoUrl,
    double? price,
    String? status,
    DateTime? createdDate,
    DateTime? dueDate,
    DateTime? completedDate,
    String? notes,
    int? syncStatus,
    DateTime? updatedAt,
  }) {
    return RepairJob(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceType: serviceType ?? this.serviceType,
      complexity: complexity ?? this.complexity,
      defectPhotoUrl: defectPhotoUrl ?? this.defectPhotoUrl,
      price: price ?? this.price,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get service display name
  String get serviceDisplayName {
    switch (serviceType) {
      case 'ZIPPER':
        return 'Chain Badlai (Zipper)';
      case 'HEM':
        return 'Turpai (Hemming)';
      case 'PICO':
        return 'Fall-Pico';
      case 'FITTING':
        return 'Fitting/Resizing';
      case 'PATCH':
        return 'Patch Work';
      default:
        return serviceType;
    }
  }

  // Helper method to get complexity multiplier
  double get complexityMultiplier {
    switch (complexity) {
      case 'SIMPLE':
        return 1.0;
      case 'MEDIUM':
        return 1.5;
      case 'COMPLEX':
        return 2.0;
      default:
        return 1.0;
    }
  }
}
