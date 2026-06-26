import 'package:sqflite_sqlcipher/sqflite.dart';
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
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE orders ADD COLUMN labor_cost REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE orders ADD COLUMN overhead_cost REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE orders ADD COLUMN advance_amount REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE orders ADD COLUMN style_attributes_json TEXT');
      await db.execute('ALTER TABLE customers ADD COLUMN ltv REAL DEFAULT 0.0');
    }
    if (oldVersion < 3) {
      // Version 3: Multi-tenancy and RBAC
      developer.log('Upgrading database to version 3...', name: 'LocalDatabaseService');
      await db.execute('''
        CREATE TABLE shop (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          address TEXT,
          owner_id TEXT,
          sync_status INTEGER DEFAULT 1,
          updated_at INTEGER NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          role TEXT NOT NULL, -- 'admin' or 'staff'
          shop_id TEXT,
          sync_status INTEGER DEFAULT 1,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (shop_id) REFERENCES shop (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      // Version 4: SRS 2.0 - Repairs, Lining, Gallery, Settings
      developer.log('Upgrading database to version 4 (SRS 2.0)...', name: 'LocalDatabaseService');
      
      await db.execute('''
        CREATE TABLE repair_jobs (
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          customer_name TEXT NOT NULL,
          service_type TEXT NOT NULL,
          complexity TEXT DEFAULT 'SIMPLE',
          defect_photo_url TEXT,
          price REAL NOT NULL,
          status TEXT DEFAULT 'pending',
          created_date INTEGER NOT NULL,
          completed_date INTEGER,
          notes TEXT,
          sync_status INTEGER DEFAULT 1,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE lining_items (
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          material_type TEXT NOT NULL,
          source TEXT NOT NULL,
          unit_price REAL NOT NULL,
          quantity REAL NOT NULL,
          notes TEXT,
          sync_status INTEGER DEFAULT 1,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE gallery_items (
          id TEXT PRIMARY KEY,
          image_url TEXT NOT NULL,
          fabric_tags TEXT,
          garment_tags TEXT,
          source TEXT DEFAULT 'USER_UPLOAD',
          reference_url TEXT,
          title TEXT,
          description TEXT,
          sync_status INTEGER DEFAULT 1,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE shop_settings (
          key TEXT PRIMARY KEY,
          value TEXT,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Add new columns to orders table for material management
      await db.execute('ALTER TABLE orders ADD COLUMN fabric_photo_url TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN astar_required INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE orders ADD COLUMN astar_source TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN astar_cost REAL DEFAULT 0.0');

      // Add new columns to measurements table for dual-mode
      await db.execute('ALTER TABLE measurements ADD COLUMN measurement_mode TEXT DEFAULT "body"');
      await db.execute('ALTER TABLE measurements ADD COLUMN garment_type TEXT');
      await db.execute('ALTER TABLE measurements ADD COLUMN stretch_factor INTEGER DEFAULT 0');

      developer.log('Database upgraded to version 4 successfully', name: 'LocalDatabaseService');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log('Creating local database tables...', name: 'LocalDatabaseService');

    // Shop Table
    await db.execute('''
      CREATE TABLE shop (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        owner_id TEXT,
        sync_status INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Users Table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        role TEXT NOT NULL,
        shop_id TEXT,
        sync_status INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (shop_id) REFERENCES shop (id) ON DELETE CASCADE
      )
    ''');

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

    // Repair Jobs Table (SRS Phase 5: Repairs Module)
    await db.execute('''
      CREATE TABLE repair_jobs (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        service_type TEXT NOT NULL,
        complexity TEXT DEFAULT 'SIMPLE',
        defect_photo_url TEXT,
        price REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        created_date INTEGER NOT NULL,
        completed_date INTEGER,
        notes TEXT,
        sync_status INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Lining Items Table (SRS Phase 4: Astar Management)
    await db.execute('''
      CREATE TABLE lining_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        material_type TEXT NOT NULL,
        source TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity REAL NOT NULL,
        notes TEXT,
        sync_status INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // Gallery Items Table (SRS Phase 6: Design Consultation)
    await db.execute('''
      CREATE TABLE gallery_items (
        id TEXT PRIMARY KEY,
        image_url TEXT NOT NULL,
        fabric_tags TEXT,
        garment_tags TEXT,
        source TEXT DEFAULT 'USER_UPLOAD',
        reference_url TEXT,
        title TEXT,
        description TEXT,
        sync_status INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Shop Settings Table (SRS Phase 7: Rate Card & Branding)
    await db.execute('''
      CREATE TABLE shop_settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');

    developer.log('Database tables created successfully', name: 'LocalDatabaseService');
  }

  // ============== USER CRUD ==============
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUser(String id) async {
    final db = await database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final db = await database;
    final results = await db.query('users', where: 'phone = ?', whereArgs: [phone]);
    return results.isNotEmpty ? results.first : null;
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

  // ============== REPAIR JOBS CRUD ==============
  Future<void> insertRepairJob(Map<String, dynamic> job) async {
    final db = await database;
    await db.insert('repair_jobs', job, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllRepairJobs() async {
    final db = await database;
    return await db.query('repair_jobs', where: 'sync_status != 2', orderBy: 'created_date DESC');
  }

  Future<void> deleteRepairJob(String id) async {
    final db = await database;
    await db.update('repair_jobs', {'sync_status': 2}, where: 'id = ?', whereArgs: [id]);
  }

  // ============== LINING ITEMS CRUD ==============
  Future<void> insertLiningItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('lining_items', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getLiningItemsByOrder(String orderId) async {
    final db = await database;
    return await db.query('lining_items', where: 'order_id = ? AND sync_status != 2', whereArgs: [orderId]);
  }

  Future<void> deleteLiningItem(String id) async {
    final db = await database;
    await db.update('lining_items', {'sync_status': 2}, where: 'id = ?', whereArgs: [id]);
  }

  // ============== GALLERY ITEMS CRUD ==============
  Future<void> insertGalleryItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('gallery_items', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllGalleryItems() async {
    final db = await database;
    return await db.query('gallery_items', where: 'sync_status != 2', orderBy: 'updated_at DESC');
  }

  Future<void> deleteGalleryItem(String id) async {
    final db = await database;
    await db.update('gallery_items', {'sync_status': 2}, where: 'id = ?', whereArgs: [id]);
  }

  // ============== SYNC HELPERS ==============
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    final db = await database;
    return await db.query(table, where: 'sync_status != 0');
  }
}
