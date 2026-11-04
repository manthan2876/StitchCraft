import 'dart:convert';

enum UserRole {
  owner,
  manager,
  staff,
  karigar;

  // Backward compatibility alias for legacy references
  static const UserRole admin = UserRole.owner;

  bool get isAdmin => this == UserRole.owner || this == UserRole.manager;
  bool get isOwner => this == UserRole.owner;
  bool get isManager => this == UserRole.manager;
  bool get isStaff => this == UserRole.staff;
  bool get isKarigar => this == UserRole.karigar;

  bool get canManageShop => this == UserRole.owner || this == UserRole.manager;
  bool get canDeleteShop => this == UserRole.owner;
  bool get canManageStaff => this == UserRole.owner || this == UserRole.manager;
  bool get canDeleteOrders => this == UserRole.owner || this == UserRole.manager;
  bool get canViewFinancials => this == UserRole.owner || this == UserRole.manager;

  static UserRole fromString(String? roleStr) {
    if (roleStr == null) return UserRole.staff;
    final clean = roleStr.toLowerCase().trim();
    if (clean == 'owner' || clean == 'admin') return UserRole.owner;
    if (clean == 'manager') return UserRole.manager;
    if (clean == 'karigar') return UserRole.karigar;
    return UserRole.staff;
  }
}

class User {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? shopId;
  final int syncStatus; // 0: synced, 1: pending, 2: deleted
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.shopId,
    this.syncStatus = 1,
    required this.updatedAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? phone,
    UserRole? role,
    String? shopId,
    int? syncStatus,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'shop_id': shopId,
      'sync_status': syncStatus,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.fromString(map['role']?.toString()),
      shopId: map['shop_id'],
      syncStatus: map['sync_status']?.toInt() ?? 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(id: $id, name: $name, role: $role, shopId: $shopId)';
  }
}
