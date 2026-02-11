import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  static Database? _database;

  LocalDatabaseService._internal();

  factory LocalDatabaseService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stitchcraft_local.db');

    return await openDatabase(
      path,
      password: 'stitchcraft_secure_key_2026', // SRS ARCH-002: Encryption at Rest
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE orders ADD COLUMN labor_cost REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE orders ADD COLUMN overhead_cost REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE orders ADD COLUMN advance_amount REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE orders ADD COLUMN style_attributes_json TEXT');
      await db.execute('ALTER TABLE customers ADD COLUMN ltv REAL DEFAULT 0.0');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log('Creating local database tables...', name: 'LocalDatabaseService');

    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        photo_uri TEXT,
        physical_attributes TEXT, -- JSON
        soft_preferences TEXT,    -- JSON
        rating REAL,
        loyalty_points INTEGER,
        ltv REAL DEFAULT 0.0,
        sync_status INTEGER DEFAULT 1, -- 0: synced, 1: pending, 2: deleted_locally
        updated_at INTEGER NOT NULL
      )
    ''');

    // Measurements Table
    await db.execute('''
      CREATE TABLE measurements (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        order_id TEXT,
        item_type TEXT NOT NULL,
        measurements_json TEXT NOT NULL, -- JSON
        measurement_date INTEGER NOT NULL,
        notes TEXT,
        sync_status INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Orders Table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        order_date INTEGER NOT NULL,
        due_date INTEGER,
        status TEXT NOT NULL,
        total_amount REAL NOT NULL,
        description TEXT,
        item_types TEXT, -- Comma-separated or JSON
        is_rush INTEGER DEFAULT 0,
        payment_method TEXT,
        labor_cost REAL DEFAULT 0.0,
        material_cost REAL DEFAULT 0.0,
        overhead_cost REAL DEFAULT 0.0,
        advance_amount REAL DEFAULT 0.0,
        style_attributes_json TEXT,
        sync_status INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Inventory Table
    await db.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        low_stock_threshold REAL,
        sync_status INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  // ============== CUSTOMER CRUD ==============
  Future<void> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    await db.insert('customers', customer, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    return await db.query('customers', where: 'sync_status != 2');
  }

  Future<Map<String, dynamic>?> getCustomer(String id) async {
    final db = await database;
    final results = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateSyncStatus(String table, String id, int status) async {
    final db = await database;
    await db.update(table, {'sync_status': status}, where: 'id = ?', whereArgs: [id]);
  }

  // ============== MEASUREMENT CRUD ==============
  Future<void> insertMeasurement(Map<String, dynamic> measurement) async {
    final db = await database;
    await db.insert('measurements', measurement, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMeasurementsByCustomer(String customerId) async {
    final db = await database;
    return await db.query('measurements', where: 'customer_id = ? AND sync_status != 2', whereArgs: [customerId]);
  }

  // ============== ORDER CRUD ==============
  Future<void> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    await db.insert('orders', order, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await database;
    return await db.query('orders', where: 'sync_status != 2', orderBy: 'order_date DESC');
  }

  // ============== EXPENSE CRUD ==============
  Future<void> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    await db.insert('expenses', expense, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await database;
    return await db.query('expenses', where: 'sync_status != 2', orderBy: 'date DESC');
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.update('expenses', {'sync_status': 2}, where: 'id = ?', whereArgs: [id]); // Soft delete
  }

  // ============== SYNC HELPERS ==============
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    final db = await database;
    return await db.query(table, where: 'sync_status != 0');
  }
}
