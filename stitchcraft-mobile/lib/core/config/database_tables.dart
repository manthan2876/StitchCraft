/* lib/core/config/database_tables.dart */

const List<String> createTableStatements = [
  // Shop Table
  '''
  CREATE TABLE shop (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    owner_id TEXT,
    sync_status INTEGER DEFAULT 1,
    updated_at INTEGER NOT NULL
  )
  ''',
  // Users Table
  '''
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
  ''',
  // Customers Table
  '''
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
  ''',
  // Measurements Table
  '''
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
    measurement_mode TEXT DEFAULT "body",
    garment_type TEXT,
    stretch_factor INTEGER DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
  )
  ''',
  // Orders Table
  '''
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
    fabric_photo_url TEXT,
    astar_required INTEGER DEFAULT 0,
    astar_source TEXT,
    astar_cost REAL DEFAULT 0.0,
    sync_status INTEGER DEFAULT 1,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
  )
  ''',
  // Expenses Table
  '''
  CREATE TABLE expenses (
    id TEXT PRIMARY KEY,
    category TEXT NOT NULL,
    amount REAL NOT NULL,
    description TEXT,
    date INTEGER NOT NULL,
    sync_status INTEGER DEFAULT 1,
    updated_at INTEGER NOT NULL
  )
  ''',
  // Inventory Table
  '''
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
  ''',
  // Repair Jobs Table
  '''
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
  ''',
  // Lining Items Table
  '''
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
  ''',
  // Gallery Items Table
  '''
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
  ''',
  // Shop Settings Table
  '''
  CREATE TABLE shop_settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at INTEGER NOT NULL
  )
  ''',
];

const Map<int, List<String>> upgradeTableStatements = {
  2: [
    'ALTER TABLE orders ADD COLUMN labor_cost REAL DEFAULT 0.0',
    'ALTER TABLE orders ADD COLUMN overhead_cost REAL DEFAULT 0.0',
    'ALTER TABLE orders ADD COLUMN advance_amount REAL DEFAULT 0.0',
    'ALTER TABLE orders ADD COLUMN style_attributes_json TEXT',
    'ALTER TABLE customers ADD COLUMN ltv REAL DEFAULT 0.0',
  ],
  3: [
    '''
    CREATE TABLE shop (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      address TEXT,
      owner_id TEXT,
      sync_status INTEGER DEFAULT 1,
      updated_at INTEGER NOT NULL
    )
    ''',
    '''
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
    ''',
  ],
  4: [
    '''
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
    ''',
    '''
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
    ''',
    '''
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
    ''',
    '''
    CREATE TABLE shop_settings (
      key TEXT PRIMARY KEY,
      value TEXT,
      updated_at INTEGER NOT NULL
    )
    ''',
    'ALTER TABLE orders ADD COLUMN fabric_photo_url TEXT',
    'ALTER TABLE orders ADD COLUMN astar_required INTEGER DEFAULT 0',
    'ALTER TABLE orders ADD COLUMN astar_source TEXT',
    'ALTER TABLE orders ADD COLUMN astar_cost REAL DEFAULT 0.0',
    'ALTER TABLE measurements ADD COLUMN measurement_mode TEXT DEFAULT "body"',
    'ALTER TABLE measurements ADD COLUMN garment_type TEXT',
    'ALTER TABLE measurements ADD COLUMN stretch_factor INTEGER DEFAULT 0',
  ],
};
