import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;
import '../config/database_tables.dart';

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
    final path = join(await getDatabasesPath(), 'stitchcraft_v1.db');

    return await openDatabase(
      path,
      password: 'stitchcraft_secure_key_2026', // SRS ARCH-002: Encryption at Rest
      version: 4, // Incremented for new tables
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from version $oldVersion to $newVersion...', name: 'LocalDatabaseService');
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      final statements = upgradeTableStatements[version];
      if (statements != null) {
        for (final statement in statements) {
          await db.execute(statement);
        }
      }
    }
    developer.log('Database upgraded successfully', name: 'LocalDatabaseService');
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log('Creating local database tables...', name: 'LocalDatabaseService');
    for (final statement in createTableStatements) {
      await db.execute(statement);
    }
    developer.log('Database tables created successfully', name: 'LocalDatabaseService');
  }

  // ============== GENERIC CRUD HELPERS ==============
  Future<void> insertRecord(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getRecordById(String table, String id, {String idColumn = 'id'}) async {
    final db = await database;
    final results = await db.query(table, where: '$idColumn = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getRecords(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final db = await database;
    final baseWhere = 'sync_status != 2';
    final resolvedWhere = where != null ? '$baseWhere AND ($where)' : baseWhere;
    return await db.query(table, where: resolvedWhere, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<void> softDeleteRecord(String table, String id, {String idColumn = 'id'}) async {
    final db = await database;
    await db.update(table, {'sync_status': 2}, where: '$idColumn = ?', whereArgs: [id]);
  }

  // ============== USER CRUD ==============
  Future<void> insertUser(Map<String, dynamic> user) => insertRecord('users', user);
  Future<Map<String, dynamic>?> getUser(String id) => getRecordById('users', id);
  Future<Map<String, dynamic>?> getUserByPhone(String phone) => getRecordById('users', phone, idColumn: 'phone');
  
  // ============== CUSTOMER CRUD ==============
  Future<void> insertCustomer(Map<String, dynamic> customer) => insertRecord('customers', customer);
  Future<List<Map<String, dynamic>>> getCustomers() => getRecords('customers');
  Future<Map<String, dynamic>?> getCustomer(String id) => getRecordById('customers', id);
  
  Future<void> updateSyncStatus(String table, String id, int status) async {
    final db = await database;
    await db.update(table, {'sync_status': status}, where: 'id = ?', whereArgs: [id]);
  }

  // ============== MEASUREMENT CRUD ==============
  Future<void> insertMeasurement(Map<String, dynamic> measurement) => insertRecord('measurements', measurement);
  Future<List<Map<String, dynamic>>> getMeasurementsByCustomer(String customerId) =>
      getRecords('measurements', where: 'customer_id = ?', whereArgs: [customerId]);

  // ============== ORDER CRUD ==============
  Future<void> insertOrder(Map<String, dynamic> order) => insertRecord('orders', order);
  Future<List<Map<String, dynamic>>> getAllOrders() => getRecords('orders', orderBy: 'order_date DESC');

  // ============== EXPENSE CRUD ==============
  Future<void> insertExpense(Map<String, dynamic> expense) => insertRecord('expenses', expense);
  Future<List<Map<String, dynamic>>> getAllExpenses() => getRecords('expenses', orderBy: 'date DESC');
  Future<void> deleteExpense(String id) => softDeleteRecord('expenses', id);

  // ============== REPAIR JOBS CRUD ==============
  Future<void> insertRepairJob(Map<String, dynamic> job) => insertRecord('repair_jobs', job);
  Future<List<Map<String, dynamic>>> getAllRepairJobs() => getRecords('repair_jobs', orderBy: 'created_date DESC');
  Future<void> deleteRepairJob(String id) => softDeleteRecord('repair_jobs', id);

  // ============== LINING ITEMS CRUD ==============
  Future<void> insertLiningItem(Map<String, dynamic> item) => insertRecord('lining_items', item);
  Future<List<Map<String, dynamic>>> getLiningItemsByOrder(String orderId) =>
      getRecords('lining_items', where: 'order_id = ?', whereArgs: [orderId]);
  Future<void> deleteLiningItem(String id) => softDeleteRecord('lining_items', id);

  // ============== GALLERY ITEMS CRUD ==============
  Future<void> insertGalleryItem(Map<String, dynamic> item) => insertRecord('gallery_items', item);
  Future<List<Map<String, dynamic>>> getAllGalleryItems() => getRecords('gallery_items', orderBy: 'updated_at DESC');
  Future<void> deleteGalleryItem(String id) => softDeleteRecord('gallery_items', id);

  // ============== SYNC HELPERS ==============
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    final db = await database;
    return await db.query(table, where: 'sync_status != 0');
  }
}
