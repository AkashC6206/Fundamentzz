import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SqliteDataSource {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Enable FFI for Linux / Windows / MacOS desktop platforms and unit test runners
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = 'fundamentzz_pos.db';
    } else {
      try {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, 'fundamentzz_pos.db');
      } catch (e) {
        // Fallback for tests or environments where path_provider channel is unavailable
        path = inMemoryDatabasePath;
      }
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onOpen(Database db) async {
    await _ensurePrinterSettingsTable(db);
    await _ensureBillCustomizerTable(db);
    await _ensureProductsTableColumns(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureProductsTableColumns(db);
    if (oldVersion < 3) {
      await _ensurePrinterSettingsTable(db);
      await _ensureBillCustomizerTable(db);
    }
  }

  Future<void> _ensureProductsTableColumns(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(products)');
      final columnNames = tableInfo.map((col) => col['name'] as String).toSet();
      if (!columnNames.contains('category_name')) {
        await db.execute("ALTER TABLE products ADD COLUMN category_name TEXT NOT NULL DEFAULT 'General'");
      }
      if (!columnNames.contains('cost_price')) {
        await db.execute('ALTER TABLE products ADD COLUMN cost_price REAL NOT NULL DEFAULT 0.0');
      }
      if (!columnNames.contains('stock_quantity')) {
        await db.execute('ALTER TABLE products ADD COLUMN stock_quantity REAL NOT NULL DEFAULT 0.0');
      }
      if (!columnNames.contains('low_stock_threshold')) {
        await db.execute('ALTER TABLE products ADD COLUMN low_stock_threshold REAL NOT NULL DEFAULT 5.0');
      }
      if (!columnNames.contains('unit')) {
        await db.execute("ALTER TABLE products ADD COLUMN unit TEXT NOT NULL DEFAULT 'portion'");
      }
      if (!columnNames.contains('barcode')) {
        await db.execute("ALTER TABLE products ADD COLUMN barcode TEXT NOT NULL DEFAULT ''");
      }
      if (!columnNames.contains('image_path')) {
        await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
      }
      if (!columnNames.contains('color_value')) {
        await db.execute('ALTER TABLE products ADD COLUMN color_value INTEGER NOT NULL DEFAULT 4280172510');
      }
      if (!columnNames.contains('tax_rate')) {
        await db.execute('ALTER TABLE products ADD COLUMN tax_rate REAL NOT NULL DEFAULT 5.0');
      }
      if (!columnNames.contains('is_available')) {
        await db.execute('ALTER TABLE products ADD COLUMN is_available INTEGER NOT NULL DEFAULT 1');
      }
    } catch (e) {
      debugPrint('DB table migration note (products): $e');
    }
  }

  Future<void> _ensurePrinterSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS printer_settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        saved_mac TEXT,
        saved_name TEXT,
        paper_size TEXT NOT NULL DEFAULT '80mm',
        auto_print_on_sale INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.insert('printer_settings', {
      'id': 1,
      'saved_mac': null,
      'saved_name': null,
      'paper_size': '80mm',
      'auto_print_on_sale': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _ensureBillCustomizerTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bill_customizer (
        id INTEGER PRIMARY KEY DEFAULT 1,
        show_business_name INTEGER NOT NULL DEFAULT 1,
        show_tagline INTEGER NOT NULL DEFAULT 1,
        show_address INTEGER NOT NULL DEFAULT 1,
        show_phone INTEGER NOT NULL DEFAULT 1,
        show_tax_id INTEGER NOT NULL DEFAULT 1,
        show_invoice_number INTEGER NOT NULL DEFAULT 1,
        show_date_time INTEGER NOT NULL DEFAULT 1,
        show_customer_details INTEGER NOT NULL DEFAULT 1,
        show_payment_mode INTEGER NOT NULL DEFAULT 1,
        show_item_price INTEGER NOT NULL DEFAULT 1,
        show_subtotal INTEGER NOT NULL DEFAULT 1,
        show_grand_total INTEGER NOT NULL DEFAULT 1,
        show_cash_change INTEGER NOT NULL DEFAULT 1,
        show_footer INTEGER NOT NULL DEFAULT 1,
        show_order_ticket_kot INTEGER NOT NULL DEFAULT 1,
        cut_paper INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.insert('bill_customizer', {
      'id': 1,
      'show_business_name': 1,
      'show_tagline': 1,
      'show_address': 1,
      'show_phone': 1,
      'show_tax_id': 1,
      'show_invoice_number': 1,
      'show_date_time': 1,
      'show_customer_details': 1,
      'show_payment_mode': 1,
      'show_item_price': 1,
      'show_subtotal': 1,
      'show_grand_total': 1,
      'show_cash_change': 1,
      'show_footer': 1,
      'show_order_ticket_kot': 1,
      'cut_paper': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'restaurant',
        color_value INTEGER NOT NULL DEFAULT 4280172510
      )
    ''');

    // 2. Products Table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        selling_price REAL NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0.0,
        stock_quantity REAL NOT NULL DEFAULT 0.0,
        low_stock_threshold REAL NOT NULL DEFAULT 5.0,
        unit TEXT NOT NULL DEFAULT 'portion',
        barcode TEXT NOT NULL DEFAULT '',
        image_path TEXT,
        color_value INTEGER NOT NULL DEFAULT 4280172510,
        tax_rate REAL NOT NULL DEFAULT 5.0,
        is_available INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 3. Sales Table
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        subtotal REAL NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        tax_amount REAL NOT NULL DEFAULT 0.0,
        service_charge REAL NOT NULL DEFAULT 0.0,
        round_off REAL NOT NULL DEFAULT 0.0,
        total_amount REAL NOT NULL,
        cost_total REAL NOT NULL DEFAULT 0.0,
        payment_mode TEXT NOT NULL,
        cash_tendered REAL NOT NULL DEFAULT 0.0,
        change_returned REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'completed',
        payment_reference TEXT,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');

    // 4. Sale Items Table
    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        category_name TEXT NOT NULL DEFAULT '',
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0.0,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        tax_amount REAL NOT NULL DEFAULT 0.0,
        total_amount REAL NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    // 5. Held Bills Table
    await db.execute('''
      CREATE TABLE held_bills (
        id TEXT PRIMARY KEY,
        table_or_reference TEXT NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        items_json TEXT NOT NULL,
        total_amount REAL NOT NULL,
        held_at TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');

    // 6. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        credit_balance REAL NOT NULL DEFAULT 0.0,
        credit_limit REAL NOT NULL DEFAULT 10000.0,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // 7. Customer Ledger Entries Table
    await db.execute('''
      CREATE TABLE customer_ledger (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        sale_id TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        balance_after REAL NOT NULL,
        timestamp TEXT NOT NULL,
        payment_mode TEXT NOT NULL DEFAULT 'Cash',
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // 8. Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_mode TEXT NOT NULL DEFAULT 'Cash',
        date TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');

    // 9. Stock Adjustments Table
    await db.execute('''
      CREATE TABLE stock_adjustments (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity_change REAL NOT NULL,
        new_stock_quantity REAL NOT NULL,
        reason TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');

    // 10. Business Profile Table
    await db.execute('''
      CREATE TABLE business_profile (
        id INTEGER PRIMARY KEY DEFAULT 1,
        restaurant_name TEXT NOT NULL,
        tagline TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        tax_registration_number TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        receipt_footer TEXT NOT NULL,
        upi_vpa TEXT NOT NULL,
        logo_path TEXT
      )
    ''');

    // 11. Tax Settings Table
    await db.execute('''
      CREATE TABLE tax_settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        is_tax_enabled INTEGER NOT NULL DEFAULT 1,
        is_tax_inclusive INTEGER NOT NULL DEFAULT 0,
        tax_name TEXT NOT NULL DEFAULT 'GST',
        default_tax_rate REAL NOT NULL DEFAULT 5.0,
        service_charge_rate REAL NOT NULL DEFAULT 0.0,
        is_service_charge_enabled INTEGER NOT NULL DEFAULT 0,
        is_round_off_enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 12. Printer Settings Table
    await db.execute('''
      CREATE TABLE printer_settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        saved_mac TEXT,
        saved_name TEXT,
        paper_size TEXT NOT NULL DEFAULT '80mm',
        auto_print_on_sale INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insert Default Profile and Tax Settings
    await db.insert('business_profile', {
      'id': 1,
      'restaurant_name': 'Fundamentzz Bistro & Cafe',
      'tagline': 'Innovation Starts with Fundamentals',
      'address': 'Tech Hub Plaza, Silicon Sector, Bangalore',
      'phone': '+91 98765 43210',
      'email': 'contact@fundamentzz.pos',
      'tax_registration_number': '29ABCDE1234F1Z5',
      'currency_symbol': '₹',
      'receipt_footer': 'Thank you for dining with us! Please visit again.',
      'upi_vpa': 'fundamentzz@okhdfcbank',
      'logo_path': null,
    });

    await db.insert('tax_settings', {
      'id': 1,
      'is_tax_enabled': 1,
      'is_tax_inclusive': 0,
      'tax_name': 'GST',
      'default_tax_rate': 5.0,
      'service_charge_rate': 0.0,
      'is_service_charge_enabled': 0,
      'is_round_off_enabled': 1,
    });

    // 12. Printer Settings Table
    await _ensurePrinterSettingsTable(db);

    // 13. Bill Customizer Table
    await _ensureBillCustomizerTable(db);

    // Note: Default categories are NOT auto-initialized on first launch per requirements
  }

  Future<Map<String, dynamic>?> getPrinterSettings() async {
    try {
      final db = await database;
      await _ensurePrinterSettingsTable(db);
      final res = await db.query('printer_settings', where: 'id = ?', whereArgs: [1]);
      if (res.isNotEmpty) return res.first;
      return null;
    } catch (e) {
      debugPrint('Error querying printer_settings: $e');
      return null;
    }
  }

  Future<void> savePrinterSettings({
    String? mac,
    String? name,
    String paperSize = '80mm',
    bool autoPrint = false,
  }) async {
    try {
      final db = await database;
      await _ensurePrinterSettingsTable(db);
      await db.insert(
        'printer_settings',
        {
          'id': 1,
          'saved_mac': mac,
          'saved_name': name,
          'paper_size': paperSize,
          'auto_print_on_sale': autoPrint ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving printer_settings, re-ensuring table: $e');
      try {
        final db = await database;
        await _ensurePrinterSettingsTable(db);
        await db.insert(
          'printer_settings',
          {
            'id': 1,
            'saved_mac': mac,
            'saved_name': name,
            'paper_size': paperSize,
            'auto_print_on_sale': autoPrint ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (err) {
        debugPrint('Final error saving printer settings: $err');
      }
    }
  }

  Future<Map<String, dynamic>?> getBillCustomizerSettings() async {
    try {
      final db = await database;
      await _ensureBillCustomizerTable(db);
      final res = await db.query('bill_customizer', where: 'id = ?', whereArgs: [1]);
      if (res.isNotEmpty) return res.first;
      return null;
    } catch (e) {
      debugPrint('Error querying bill_customizer: $e');
      return null;
    }
  }

  Future<void> saveBillCustomizerSettings(Map<String, dynamic> settingsMap) async {
    final map = Map<String, dynamic>.from(settingsMap);
    map['id'] = 1;
    try {
      final db = await database;
      await _ensureBillCustomizerTable(db);
      await db.insert(
        'bill_customizer',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving bill_customizer, re-ensuring table: $e');
      try {
        final db = await database;
        await _ensureBillCustomizerTable(db);
        await db.insert(
          'bill_customizer',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (err) {
        debugPrint('Final error saving bill customizer settings: $err');
      }
    }
  }

  Future<void> ensureDefaultCategories() async {
    // Deliberately no-op: Do not auto-initialize categories at first of app.
  }

  /// Cleans up uncustomized initial default categories if they have no products
  Future<void> cleanupUnusedDefaultCategories() async {
    final db = await database;
    final defaultIds = [
      'cat_starters',
      'cat_mains',
      'cat_rice',
      'cat_beverages',
      'cat_desserts',
      'cat_snacks',
    ];
    for (final id in defaultIds) {
      final res = await db.rawQuery('SELECT COUNT(*) as count FROM products WHERE category_id = ?', [id]);
      final count = (res.firstOrNull?['count'] as num?)?.toInt() ?? 0;
      if (count == 0) {
        await db.delete('categories', where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('sale_items');
    await db.delete('sales');
    await db.delete('held_bills');
    await db.delete('customer_ledger');
    await db.delete('customers');
    await db.delete('expenses');
    await db.delete('stock_adjustments');
    await db.delete('products');
    await db.delete('categories');
  }
}
