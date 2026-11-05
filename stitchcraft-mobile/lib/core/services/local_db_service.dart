import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:developer' as developer;
import '../config/database_tables.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();
  static Database? _database;
  static Completer<Database>? _dbOpenCompleter;
  static final Map<String, List<Map<String, dynamic>>> _webDb = {};

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const String _dbKeyStorageKey = 'stitchcraft_sqlcipher_key_v1';
  static const String _legacyCommittedKey = 'stitchcraft_secure_key_2026';

  LocalDatabaseService._internal();

  factory LocalDatabaseService() => _instance;

  Future<void> _initWebDb() async {
    final tables = [
      'users',
      'customers',
      'measurements',
      'orders',
      'expenses',
      'repair_jobs',
      'lining_items',
      'gallery_items',
      'inventory',
      'order_payments',
    ];
    for (final table in tables) {
      _webDb.putIfAbsent(table, () => []);
    }
  }

  Future<Database?> get database async {
    if (kIsWeb) {
      await _initWebDb();
      return null;
    }
    if (_database != null && _database!.isOpen) return _database!;
    if (_dbOpenCompleter != null) return await _dbOpenCompleter!.future;

    _dbOpenCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();
      _dbOpenCompleter!.complete(_database);
      return _database!;
    } catch (e, stack) {
      _dbOpenCompleter!.completeError(e, stack);
      _database = null;
      rethrow;
    } finally {
      _dbOpenCompleter = null;
    }
  }

  Future<String> _getOrGenerateDatabaseKey() async {
    var key = await _secureStorage.read(key: _dbKeyStorageKey);
    if (key != null && key.isNotEmpty) {
      return key;
    }

    // Generate a 256-bit cryptographically secure random key
    final randomBytes = List<int>.generate(
      32,
      (_) => Random.secure().nextInt(256),
    );
    key = base64UrlEncode(randomBytes);
    await _secureStorage.write(key: _dbKeyStorageKey, value: key);
    return key;
  }

  Future<Database> _initDatabase() async {
    final path = p.join(await getDatabasesPath(), 'stitchcraft_v1.db');
    final secureKey = await _getOrGenerateDatabaseKey();

    try {
      final db = await openDatabase(
        path,
        password: secureKey,
        version: 8, // Incremented to 8 for tenant isolation & shop_id columns
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
      await _ensureAllRequiredColumns(db);
      return db;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final isDecryptionError = errStr.contains('not a database') ||
          errStr.contains('code 26') ||
          errStr.contains('file is not a database') ||
          errStr.contains('hmac check failed');

      if (!isDecryptionError) {
        developer.log(
          'Database open failed with non-decryption error: $e',
          name: 'LocalDatabaseService',
          error: e,
        );
        rethrow;
      }

      // Database may have been encrypted with the legacy committed key
      try {
        final legacyDb = await openDatabase(
          path,
          password: _legacyCommittedKey,
        );
        await legacyDb.rawQuery("PRAGMA rekey = '$secureKey';");
        await legacyDb.close();
        developer.log(
          'Successfully re-keyed database to hardware-backed key',
          name: 'LocalDatabaseService',
        );

        final recoveredDb = await openDatabase(
          path,
          password: secureKey,
          version: 8,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
        );
        await _ensureAllRequiredColumns(recoveredDb);
        return recoveredDb;
      } catch (migrationErr) {
        developer.log(
          'Could not open or migrate the local database: $migrationErr',
          name: 'LocalDatabaseService',
          error: migrationErr,
        );
        throw StateError(
          'Local database recovery failed. Existing data was preserved.',
        );
      }
    }
  }

  Future<void> _safeExecute(Database db, String statement) async {
    try {
      await db.execute(statement);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('duplicate column name') ||
          msg.contains('already exists')) {
        developer.log(
          'Notice: migration statement skipped ($e)',
          name: 'LocalDatabaseService',
        );
        return;
      }
      rethrow;
    }
  }

  Future<void> _ensureColumnExists(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      final hasColumn = columns.any(
        (col) => col['name']?.toString().toLowerCase() == column.toLowerCase(),
      );
      if (!hasColumn) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('duplicate column name')) {
        return;
      }
      developer.log(
        'Error ensuring column $table.$column: $e',
        name: 'LocalDatabaseService',
      );
    }
  }

  Future<void> _ensureAllRequiredColumns(Database db) async {
    try {
      // 1. Ensure order_payments table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS order_payments (
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          amount REAL NOT NULL,
          payment_method TEXT,
          date INTEGER NOT NULL,
          shop_id TEXT,
          sync_status INTEGER DEFAULT 1,
          updated_at INTEGER NOT NULL
        )
      ''');

      // 2. Ensure shop_id on all tenant-isolated tables
      await _ensureColumnExists(db, 'orders', 'shop_id', 'TEXT');
      await _ensureColumnExists(db, 'customers', 'shop_id', 'TEXT');
      await _ensureColumnExists(db, 'expenses', 'shop_id', 'TEXT');
      await _ensureColumnExists(db, 'expenses', 'type', "TEXT DEFAULT 'expense'");
      await _ensureColumnExists(db, 'order_payments', 'shop_id', 'TEXT');
      await _ensureColumnExists(db, 'inventory', 'shop_id', 'TEXT');
      await _ensureColumnExists(db, 'repair_jobs', 'shop_id', 'TEXT');
      await _ensureColumnExists(db, 'measurements', 'shop_id', 'TEXT');
      await _ensureColumnExists(db, 'lining_items', 'shop_id', 'TEXT');
      await _ensureColumnExists(db, 'gallery_items', 'shop_id', 'TEXT');

      // 3. Ensure order delegation & styling columns
      await _ensureColumnExists(db, 'orders', 'delegated_to_shop_id', 'TEXT');
      await _ensureColumnExists(db, 'orders', 'delegated_to_shop_name', 'TEXT');
      await _ensureColumnExists(db, 'orders', 'delegated_to_phone', 'TEXT');
      await _ensureColumnExists(
        db,
        'orders',
        'delegation_status',
        "TEXT DEFAULT 'none'",
      );
      await _ensureColumnExists(db, 'orders', 'origin_shop_name', 'TEXT');
      await _ensureColumnExists(db, 'orders', 'origin_phone', 'TEXT');
      await _ensureColumnExists(db, 'orders', 'delegated_notes', 'TEXT');
      await _ensureColumnExists(db, 'orders', 'delegated_cost', 'REAL DEFAULT 0.0');
      await _ensureColumnExists(db, 'orders', 'fabric_photo_url', 'TEXT');
      await _ensureColumnExists(db, 'orders', 'astar_required', 'INTEGER DEFAULT 0');
      await _ensureColumnExists(db, 'orders', 'astar_source', 'TEXT');
      await _ensureColumnExists(db, 'orders', 'astar_cost', 'REAL DEFAULT 0.0');

      // 4. Ensure customer physical and preference columns
      await _ensureColumnExists(db, 'customers', 'physical_attributes', 'TEXT');
      await _ensureColumnExists(db, 'customers', 'soft_preferences', 'TEXT');
      await _ensureColumnExists(db, 'customers', 'ltv', 'REAL DEFAULT 0.0');

      // 5. Ensure measurement columns
      await _ensureColumnExists(db, 'measurements', 'measurement_mode', 'TEXT DEFAULT "body"');
      await _ensureColumnExists(db, 'measurements', 'garment_type', 'TEXT');
      await _ensureColumnExists(db, 'measurements', 'stretch_factor', 'INTEGER DEFAULT 0');
    } catch (e) {
      developer.log(
        'Warning: _ensureAllRequiredColumns encountered an error: $e',
        name: 'LocalDatabaseService',
        error: e,
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log(
      'Upgrading database from version $oldVersion to $newVersion...',
      name: 'LocalDatabaseService',
    );
    if (oldVersion < 5) {
      await _ensureColumnExists(db, 'orders', 'fabric_photo_url', 'TEXT');
    }
    if (oldVersion < 6) {
      await _ensureColumnExists(
        db,
        'expenses',
        'type',
        "TEXT DEFAULT 'expense'",
      );
    }
    if (oldVersion < 8) {
      await _ensureAllRequiredColumns(db);
    }
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      final statements = upgradeTableStatements[version];
      if (statements != null) {
        for (final statement in statements) {
          await _safeExecute(db, statement);
        }
      }
    }
    developer.log(
      'Database upgraded successfully',
      name: 'LocalDatabaseService',
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log(
      'Creating local database tables...',
      name: 'LocalDatabaseService',
    );
    for (final statement in createTableStatements) {
      await db.execute(statement);
    }
    developer.log(
      'Database tables created successfully',
      name: 'LocalDatabaseService',
    );
  }

  // ============== GENERIC CRUD HELPERS ==============
  Future<void> insertRecord(String table, Map<String, dynamic> data) async {
    if (kIsWeb) {
      await _initWebDb();
      final list = _webDb[table]!;
      final id = data['id'] ?? '';

      list.removeWhere((item) => item['id'] == id);
      list.add(Map<String, dynamic>.from(data));
      return;
    }
    final db = await database;
    try {
      await db!.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('no such column') || msg.contains('has no column named')) {
        await _ensureAllRequiredColumns(db!);
        await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      }
      rethrow;
    }
  }

  Future<void> updateRecord(
    String table,
    String id,
    Map<String, dynamic> data, {
    String idColumn = 'id',
  }) async {
    if (kIsWeb) {
      await _initWebDb();
      final list = _webDb[table]!;
      for (int i = 0; i < list.length; i++) {
        if (list[i][idColumn] == id) {
          final updated = Map<String, dynamic>.from(list[i]);
          updated.addAll(data);
          list[i] = updated;
          break;
        }
      }
      return;
    }
    final db = await database;
    try {
      await db!.update(
        table,
        data,
        where: '$idColumn = ?',
        whereArgs: [id],
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('no such column') || msg.contains('has no column named')) {
        await _ensureAllRequiredColumns(db!);
        await db.update(
          table,
          data,
          where: '$idColumn = ?',
          whereArgs: [id],
        );
        return;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getRecordById(
    String table,
    String id, {
    String idColumn = 'id',
  }) async {
    if (kIsWeb) {
      await _initWebDb();
      final list = _webDb[table]!;
      final match = list.where((item) => item[idColumn] == id);
      return match.isNotEmpty ? match.first : null;
    }
    final db = await database;
    final results = await db!.query(
      table,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getRecords(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    if (kIsWeb) {
      await _initWebDb();
      final list = _webDb[table]!;
      var filtered = list.where((item) => item['sync_status'] != 2).toList();

      if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
        if (where.contains('customer_id = ?')) {
          final customerId = whereArgs[0];
          filtered = filtered
              .where((item) => item['customer_id'] == customerId)
              .toList();
        } else if (where.contains('order_id = ?')) {
          final orderId = whereArgs[0];
          filtered = filtered
              .where((item) => item['order_id'] == orderId)
              .toList();
        }
      }
      return filtered;
    }
    final db = await database;
    final baseWhere = 'sync_status != 2';
    final resolvedWhere = where != null ? '$baseWhere AND ($where)' : baseWhere;
    try {
      return await db!.query(
        table,
        where: resolvedWhere,
        whereArgs: whereArgs,
        orderBy: orderBy,
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('no such column')) {
        await _ensureAllRequiredColumns(db!);
        return await db.query(
          table,
          where: resolvedWhere,
          whereArgs: whereArgs,
          orderBy: orderBy,
        );
      }
      rethrow;
    }
  }

  Future<void> softDeleteRecord(
    String table,
    String id, {
    String idColumn = 'id',
  }) async {
    if (kIsWeb) {
      await _initWebDb();
      final list = _webDb[table]!;
      for (int i = 0; i < list.length; i++) {
        if (list[i][idColumn] == id) {
          final updated = Map<String, dynamic>.from(list[i]);
          updated['sync_status'] = 2;
          list[i] = updated;
          break;
        }
      }
      return;
    }
    final db = await database;
    await db!.update(
      table,
      {'sync_status': 2},
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteRecordPermanently(
    String table,
    String id, {
    String idColumn = 'id',
  }) async {
    if (kIsWeb) {
      await _initWebDb();
      _webDb[table]!.removeWhere((item) => item[idColumn] == id);
      return;
    }
    final db = await database;
    await db!.delete(table, where: '$idColumn = ?', whereArgs: [id]);
  }

  // ============== USER CRUD ==============
  Future<void> insertUser(Map<String, dynamic> user) =>
      insertRecord('users', user);
  Future<Map<String, dynamic>?> getUser(String id) =>
      getRecordById('users', id);
  Future<Map<String, dynamic>?> getUserByPhone(String phone) =>
      getRecordById('users', phone, idColumn: 'phone');

  // ============== CUSTOMER CRUD ==============
  Future<void> insertCustomer(Map<String, dynamic> customer) =>
      insertRecord('customers', customer);
  Future<List<Map<String, dynamic>>> getCustomers({String? shopId}) {
    if (shopId != null && shopId.isNotEmpty) {
      return getRecords(
        'customers',
        where: 'shop_id IS NULL OR shop_id = "" OR shop_id = ?',
        whereArgs: [shopId],
      );
    }
    return getRecords('customers');
  }
  Future<List<Map<String, dynamic>>> getAllCustomers({String? shopId}) =>
      getCustomers(shopId: shopId);
  Future<Map<String, dynamic>?> getCustomer(String id) =>
      getRecordById('customers', id);

  Future<void> updateSyncStatus(String table, String id, int status) async {
    if (kIsWeb) {
      await _initWebDb();
      final list = _webDb[table]!;
      for (int i = 0; i < list.length; i++) {
        if (list[i]['id'] == id) {
          final updated = Map<String, dynamic>.from(list[i]);
          updated['sync_status'] = status;
          list[i] = updated;
          break;
        }
      }
      return;
    }
    final db = await database;
    await db!.update(
      table,
      {'sync_status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============== MEASUREMENT CRUD ==============
  Future<void> insertMeasurement(Map<String, dynamic> measurement) =>
      insertRecord('measurements', measurement);
  Future<List<Map<String, dynamic>>> getMeasurementsByCustomer(
    String customerId,
  ) => getRecords(
    'measurements',
    where: 'customer_id = ?',
    whereArgs: [customerId],
  );

  // ============== ORDER CRUD ==============
  Future<void> insertOrder(Map<String, dynamic> order) =>
      insertRecord('orders', order);

  Future<List<Map<String, dynamic>>> getAllOrders({String? shopId}) async {
    if (kIsWeb) {
      await _initWebDb();
      var orders = List<Map<String, dynamic>>.from(
        _webDb['orders']!.where((r) => r['sync_status'] != 2),
      );
      if (shopId != null && shopId.isNotEmpty) {
        orders = orders.where((o) =>
          o['shop_id'] == null ||
          o['shop_id'].toString().isEmpty ||
          o['shop_id'].toString() == shopId ||
          o['delegated_to_shop_id']?.toString() == shopId
        ).toList();
      }
      for (int i = 0; i < orders.length; i++) {
        final custId = orders[i]['customer_id'];
        final cust = _webDb['customers']?.firstWhere(
          (c) => c['id'] == custId,
          orElse: () => <String, dynamic>{},
        );
        if (cust != null && cust['phone'] != null) {
          final enriched = Map<String, dynamic>.from(orders[i]);
          enriched['phone'] = cust['phone'];
          orders[i] = enriched;
        }
      }
      return orders;
    }
    final db = await database;
    try {
      final String whereClause;
      final List<dynamic> whereArgs;
      if (shopId != null && shopId.isNotEmpty) {
        whereClause = 'WHERE orders.sync_status != 2 AND (orders.shop_id IS NULL OR orders.shop_id = "" OR orders.shop_id = ? OR orders.delegated_to_shop_id = ?)';
        whereArgs = [shopId, shopId];
      } else {
        whereClause = 'WHERE orders.sync_status != 2';
        whereArgs = [];
      }
      final results = await db!.rawQuery('''
        SELECT orders.*, customers.phone AS customer_phone 
        FROM orders 
        LEFT JOIN customers ON orders.customer_id = customers.id 
        $whereClause 
        ORDER BY orders.order_date DESC
      ''', whereArgs);
      return results.map((row) {
        final map = Map<String, dynamic>.from(row);
        if (map['phone'] == null || (map['phone'] as String).isEmpty) {
          map['phone'] = map['customer_phone'] ?? '';
        }
        return map;
      }).toList();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('no such column')) {
        await _ensureAllRequiredColumns(db!);
        try {
          final String whereClause;
          final List<dynamic> whereArgs;
          if (shopId != null && shopId.isNotEmpty) {
            whereClause = 'WHERE orders.sync_status != 2 AND (orders.shop_id IS NULL OR orders.shop_id = "" OR orders.shop_id = ? OR orders.delegated_to_shop_id = ?)';
            whereArgs = [shopId, shopId];
          } else {
            whereClause = 'WHERE orders.sync_status != 2';
            whereArgs = [];
          }
          final retryResults = await db.rawQuery('''
            SELECT orders.*, customers.phone AS customer_phone 
            FROM orders 
            LEFT JOIN customers ON orders.customer_id = customers.id 
            $whereClause 
            ORDER BY orders.order_date DESC
          ''', whereArgs);
          return retryResults.map((row) {
            final map = Map<String, dynamic>.from(row);
            if (map['phone'] == null || (map['phone'] as String).isEmpty) {
              map['phone'] = map['customer_phone'] ?? '';
            }
            return map;
          }).toList();
        } catch (_) {}
      }
      return getRecords('orders', orderBy: 'order_date DESC');
    }
  }

  Future<void> deleteOrder(String id) => deleteRecordPermanently('orders', id);

  // ============== EXPENSE & INCOME CRUD ==============
  Future<void> insertExpense(Map<String, dynamic> expense) =>
      insertRecord('expenses', expense);
  Future<List<Map<String, dynamic>>> getAllExpenses({String? shopId}) {
    if (shopId != null && shopId.isNotEmpty) {
      return getRecords(
        'expenses',
        where: 'shop_id IS NULL OR shop_id = "" OR shop_id = ?',
        whereArgs: [shopId],
        orderBy: 'date DESC',
      );
    }
    return getRecords('expenses', orderBy: 'date DESC');
  }
  Future<void> deleteExpense(String id) => softDeleteRecord('expenses', id);
  Future<void> insertIncome(Map<String, dynamic> income) {
    income['type'] = 'income';
    return insertRecord('expenses', income);
  }
  Future<void> deleteIncome(String id) => softDeleteRecord('expenses', id);

  // ============== REPAIR JOBS CRUD ==============
  Future<void> insertRepairJob(Map<String, dynamic> job) =>
      insertRecord('repair_jobs', job);
  Future<List<Map<String, dynamic>>> getAllRepairJobs({String? shopId}) {
    if (shopId != null && shopId.isNotEmpty) {
      return getRecords(
        'repair_jobs',
        where: 'shop_id IS NULL OR shop_id = "" OR shop_id = ?',
        whereArgs: [shopId],
        orderBy: 'created_date DESC',
      );
    }
    return getRecords('repair_jobs', orderBy: 'created_date DESC');
  }
  Future<void> deleteRepairJob(String id) =>
      softDeleteRecord('repair_jobs', id);

  // ============== LINING ITEMS CRUD ==============
  Future<void> insertLiningItem(Map<String, dynamic> item) =>
      insertRecord('lining_items', item);
  Future<List<Map<String, dynamic>>> getLiningItemsByOrder(String orderId) =>
      getRecords('lining_items', where: 'order_id = ?', whereArgs: [orderId]);
  Future<void> deleteLiningItem(String id) =>
      softDeleteRecord('lining_items', id);

  // ============== GALLERY ITEMS CRUD ==============
  Future<void> insertGalleryItem(Map<String, dynamic> item) =>
      insertRecord('gallery_items', item);
  Future<List<Map<String, dynamic>>> getAllGalleryItems({String? shopId}) {
    if (shopId != null && shopId.isNotEmpty) {
      return getRecords(
        'gallery_items',
        where: 'shop_id IS NULL OR shop_id = "" OR shop_id = ?',
        whereArgs: [shopId],
        orderBy: 'updated_at DESC',
      );
    }
    return getRecords('gallery_items', orderBy: 'updated_at DESC');
  }
  Future<void> deleteGalleryItem(String id) =>
      softDeleteRecord('gallery_items', id);

  // ============== INVENTORY CRUD ==============
  Future<List<Map<String, dynamic>>> getAllInventory({String? shopId}) {
    if (shopId != null && shopId.isNotEmpty) {
      return getRecords(
        'inventory',
        where: 'shop_id IS NULL OR shop_id = "" OR shop_id = ?',
        whereArgs: [shopId],
      );
    }
    return getRecords('inventory');
  }

  // ============== ORDER PAYMENTS CRUD ==============
  Future<void> insertPayment(Map<String, dynamic> payment) =>
      insertRecord('order_payments', payment);
  Future<List<Map<String, dynamic>>> getAllPayments({String? shopId}) async {
    if (kIsWeb) {
      await _initWebDb();
      var payments = List<Map<String, dynamic>>.from(
        _webDb['order_payments']!.where((r) => r['sync_status'] != 2),
      );
      if (shopId != null && shopId.isNotEmpty) {
        payments = payments.where((p) =>
          p['shop_id'] == null ||
          p['shop_id'].toString().isEmpty ||
          p['shop_id'].toString() == shopId
        ).toList();
      }
      return payments;
    }
    final db = await database;
    try {
      if (shopId != null && shopId.isNotEmpty) {
        return await db!.query(
          'order_payments',
          where: 'sync_status != 2 AND (shop_id IS NULL OR shop_id = "" OR shop_id = ?)',
          whereArgs: [shopId],
          orderBy: 'date DESC',
        );
      }
      return await db!.query(
        'order_payments',
        where: 'sync_status != 2',
        orderBy: 'date DESC',
      );
    } catch (_) {
      return getRecords('order_payments', orderBy: 'date DESC');
    }
  }
  Future<List<Map<String, dynamic>>> getPaymentsByOrder(String orderId) =>
      getRecords('order_payments', where: 'order_id = ?', whereArgs: [orderId]);
  Future<void> deletePayment(String id) =>
      deleteRecordPermanently('order_payments', id);

  /// Clears all local table data to guarantee complete isolation across tailor accounts
  Future<void> clearAllData() async {
    if (kIsWeb) {
      await _initWebDb();
      for (final key in _webDb.keys) {
        _webDb[key]?.clear();
      }
      return;
    }
    final db = await database;
    if (db == null) return;
    final tables = [
      'orders',
      'order_payments',
      'expenses',
      'customers',
      'measurements',
      'inventory',
      'repair_jobs',
      'lining_items',
      'gallery_items',
      'users',
      'shop',
      'shop_settings',
    ];
    for (final table in tables) {
      try {
        await db.delete(table);
      } catch (_) {}
    }
  }

  // ============== SYNC HELPERS ==============
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    if (kIsWeb) {
      await _initWebDb();
      final list = _webDb[table]!;
      return list.where((item) => item['sync_status'] != 0).toList();
    }
    final db = await database;
    return await db!.query(table, where: 'sync_status != 0');
  }

  Future<void> updateRecordId(String table, String oldId, String newId) async {
    if (kIsWeb) {
      await _initWebDb();
      final list = _webDb[table]!;
      for (int i = 0; i < list.length; i++) {
        if (list[i]['id'] == oldId) {
          final updated = Map<String, dynamic>.from(list[i]);
          updated['id'] = newId;
          updated['sync_status'] = 0;
          list[i] = updated;
          break;
        }
      }
      if (table == 'orders') {
        if (_webDb['measurements'] != null) {
          for (final m in _webDb['measurements']!) {
            if (m['order_id'] == oldId) {
              m['order_id'] = newId;
            }
          }
        }
      } else if (table == 'customers') {
        if (_webDb['measurements'] != null) {
          for (final m in _webDb['measurements']!) {
            if (m['customer_id'] == oldId) {
              m['customer_id'] = newId;
            }
          }
        }
        if (_webDb['orders'] != null) {
          for (final o in _webDb['orders']!) {
            if (o['customer_id'] == oldId) {
              o['customer_id'] = newId;
            }
          }
        }
      }
      return;
    }
    final db = await database;
    await db!.transaction((txn) async {
      await txn.update(
        table,
        {'id': newId, 'sync_status': 0},
        where: 'id = ?',
        whereArgs: [oldId],
      );
      if (table == 'orders') {
        await txn.update(
          'measurements',
          {'order_id': newId},
          where: 'order_id = ?',
          whereArgs: [oldId],
        );
      } else if (table == 'customers') {
        await txn.update(
          'measurements',
          {'customer_id': newId},
          where: 'customer_id = ?',
          whereArgs: [oldId],
        );
        await txn.update(
          'orders',
          {'customer_id': newId},
          where: 'customer_id = ?',
          whereArgs: [oldId],
        );
      }
    });
  }
}
