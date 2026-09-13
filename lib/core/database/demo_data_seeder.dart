import 'package:uuid/uuid.dart';
import '../../data/datasources/sqlite_datasource.dart';

class DemoDataSeeder {
  final SqliteDataSource _dataSource;

  DemoDataSeeder(this._dataSource);

  Future<void> seedIfEmpty() async {
    // No-op: Demo data is only loaded on explicit user request via Settings
  }

  Future<void> seedDemoData() async {
    final db = await _dataSource.database;
    await _dataSource.clearAll();

    const uuid = Uuid();
    final now = DateTime.now();

    // 1. Categories
    final catStarters = uuid.v4();
    final catMains = uuid.v4();
    final catBiryani = uuid.v4();
    final catBeverages = uuid.v4();
    final catDesserts = uuid.v4();

    final categories = [
      {'id': catStarters, 'name': 'Starters & Appetizers', 'icon': 'tapas', 'color_value': 0xFF1E5FDE},
      {'id': catMains, 'name': 'Main Course', 'icon': 'dinner_dining', 'color_value': 0xFF0F3FA8},
      {'id': catBiryani, 'name': 'Biryani & Rice', 'icon': 'rice_bowl', 'color_value': 0xFF4C8CFF},
      {'id': catBeverages, 'name': 'Beverages & Mocktails', 'icon': 'local_bar', 'color_value': 0xFF0284C7},
      {'id': catDesserts, 'name': 'Desserts', 'icon': 'icecream', 'color_value': 0xFFF5A524},
    ];

    for (final cat in categories) {
      await db.insert('categories', cat);
    }

    // 2. Products
    final prod1 = uuid.v4();
    final prod2 = uuid.v4();
    final prod3 = uuid.v4();
    final prod4 = uuid.v4();
    final prod5 = uuid.v4();
    final prod6 = uuid.v4();
    final prod7 = uuid.v4();
    final prod8 = uuid.v4();
    final prod9 = uuid.v4();
    final prod10 = uuid.v4();
    final prod11 = uuid.v4();
    final prod12 = uuid.v4();

    final products = [
      {
        'id': prod1,
        'name': 'Crispy Paneer 65',
        'category_id': catStarters,
        'category_name': 'Starters & Appetizers',
        'selling_price': 240.0,
        'cost_price': 110.0,
        'stock_quantity': 45.0,
        'low_stock_threshold': 10.0,
        'unit': 'plate',
        'barcode': '8901234501',
        'image_path': null,
        'color_value': 0xFF1E5FDE,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod2,
        'name': 'Chicken Tikka Kebab (6 Pcs)',
        'category_id': catStarters,
        'category_name': 'Starters & Appetizers',
        'selling_price': 320.0,
        'cost_price': 150.0,
        'stock_quantity': 30.0,
        'low_stock_threshold': 8.0,
        'unit': 'plate',
        'barcode': '8901234502',
        'image_path': null,
        'color_value': 0xFF1E5FDE,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod3,
        'name': 'Golden Butter Chicken',
        'category_id': catMains,
        'category_name': 'Main Course',
        'selling_price': 380.0,
        'cost_price': 180.0,
        'stock_quantity': 25.0,
        'low_stock_threshold': 5.0,
        'unit': 'portion',
        'barcode': '8901234503',
        'image_path': null,
        'color_value': 0xFF0F3FA8,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod4,
        'name': 'Paneer Butter Masala',
        'category_id': catMains,
        'category_name': 'Main Course',
        'selling_price': 290.0,
        'cost_price': 130.0,
        'stock_quantity': 35.0,
        'low_stock_threshold': 10.0,
        'unit': 'portion',
        'barcode': '8901234504',
        'image_path': null,
        'color_value': 0xFF0F3FA8,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod5,
        'name': 'Garlic Butter Naan',
        'category_id': catMains,
        'category_name': 'Main Course',
        'selling_price': 65.0,
        'cost_price': 20.0,
        'stock_quantity': 150.0,
        'low_stock_threshold': 30.0,
        'unit': 'pcs',
        'barcode': '8901234505',
        'image_path': null,
        'color_value': 0xFF0F3FA8,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod6,
        'name': 'Hyderabadi Dum Biryani (Chicken)',
        'category_id': catBiryani,
        'category_name': 'Biryani & Rice',
        'selling_price': 340.0,
        'cost_price': 160.0,
        'stock_quantity': 40.0,
        'low_stock_threshold': 10.0,
        'unit': 'pot',
        'barcode': '8901234506',
        'image_path': null,
        'color_value': 0xFF4C8CFF,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod7,
        'name': 'Royal Mutton Biryani',
        'category_id': catBiryani,
        'category_name': 'Biryani & Rice',
        'selling_price': 460.0,
        'cost_price': 240.0,
        'stock_quantity': 4.0, // Low stock on purpose
        'low_stock_threshold': 8.0,
        'unit': 'pot',
        'barcode': '8901234507',
        'image_path': null,
        'color_value': 0xFF4C8CFF,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod8,
        'name': 'Fresh Lime Mint Soda',
        'category_id': catBeverages,
        'category_name': 'Beverages & Mocktails',
        'selling_price': 110.0,
        'cost_price': 30.0,
        'stock_quantity': 80.0,
        'low_stock_threshold': 20.0,
        'unit': 'glass',
        'barcode': '8901234508',
        'image_path': null,
        'color_value': 0xFF0284C7,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod9,
        'name': 'Cold Brew Iced Coffee',
        'category_id': catBeverages,
        'category_name': 'Beverages & Mocktails',
        'selling_price': 160.0,
        'cost_price': 45.0,
        'stock_quantity': 50.0,
        'low_stock_threshold': 15.0,
        'unit': 'glass',
        'barcode': '8901234509',
        'image_path': null,
        'color_value': 0xFF0284C7,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod10,
        'name': 'Warm Sizzling Brownie with Ice Cream',
        'category_id': catDesserts,
        'category_name': 'Desserts',
        'selling_price': 190.0,
        'cost_price': 65.0,
        'stock_quantity': 2.0, // Low stock on purpose
        'low_stock_threshold': 5.0,
        'unit': 'portion',
        'barcode': '8901234510',
        'image_path': null,
        'color_value': 0xFFF5A524,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod11,
        'name': 'Gulab Jamun (2 Pcs)',
        'category_id': catDesserts,
        'category_name': 'Desserts',
        'selling_price': 90.0,
        'cost_price': 30.0,
        'stock_quantity': 60.0,
        'low_stock_threshold': 15.0,
        'unit': 'plate',
        'barcode': '8901234511',
        'image_path': null,
        'color_value': 0xFFF5A524,
        'tax_rate': 5.0,
        'is_available': 1,
      },
      {
        'id': prod12,
        'name': 'Virgin Mojito Cooler',
        'category_id': catBeverages,
        'category_name': 'Beverages & Mocktails',
        'selling_price': 140.0,
        'cost_price': 40.0,
        'stock_quantity': 3.0, // Low stock on purpose
        'low_stock_threshold': 10.0,
        'unit': 'glass',
        'barcode': '8901234512',
        'image_path': null,
        'color_value': 0xFF0284C7,
        'tax_rate': 5.0,
        'is_available': 1,
      },
    ];

    for (final prod in products) {
      await db.insert('products', prod);
    }

    // 3. Customers
    final cust1 = uuid.v4();
    final cust2 = uuid.v4();
    final cust3 = uuid.v4();

    final customers = [
      {
        'id': cust1,
        'name': 'Akash Sharma',
        'phone': '9845012345',
        'email': 'akash.s@gmail.com',
        'address': 'Flat 402, Green Residency, Indiranagar',
        'credit_balance': 1250.0, // Outstanding Udhaar
        'credit_limit': 15000.0,
        'notes': 'Regular VIP customer, Table 4 preferred',
        'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': cust2,
        'name': 'Pooja Verma',
        'phone': '9980123456',
        'email': 'pooja.v@outlook.com',
        'address': 'Silicon Heights, Koramangala 4th Block',
        'credit_balance': 0.0,
        'credit_limit': 10000.0,
        'notes': 'Corporate client for team lunches',
        'created_at': now.subtract(const Duration(days: 20)).toIso8601String(),
      },
      {
        'id': cust3,
        'name': 'Vikram Mehra',
        'phone': '9731234567',
        'email': 'vikram.m@techcorp.in',
        'address': 'Villa 12, Palm Meadows, Whitefield',
        'credit_balance': 450.0,
        'credit_limit': 8000.0,
        'notes': 'Prefers weekend dinners with family',
        'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
      },
    ];

    for (final cust in customers) {
      await db.insert('customers', cust);
    }

    // Customer ledger entry for customer 1
    await db.insert('customer_ledger', {
      'id': uuid.v4(),
      'customer_id': cust1,
      'sale_id': null,
      'type': 'creditSale',
      'amount': 1250.0,
      'balance_after': 1250.0,
      'timestamp': now.subtract(const Duration(days: 3)).toIso8601String(),
      'payment_mode': 'Credit (Udhaar)',
      'notes': 'Invoice #FZ-1002 credit purchase',
    });

    // Customer ledger entry for customer 3
    await db.insert('customer_ledger', {
      'id': uuid.v4(),
      'customer_id': cust3,
      'sale_id': null,
      'type': 'creditSale',
      'amount': 450.0,
      'balance_after': 450.0,
      'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
      'payment_mode': 'Credit (Udhaar)',
      'notes': 'Invoice #FZ-1008 credit purchase',
    });

    // 4. Past 7 Days Sales for Trend & Reports
    final salesSeeds = [
      // Day -6
      _createSaleSeed(
        id: uuid.v4(),
        invoiceNumber: 'FZ-1001',
        createdAt: now.subtract(const Duration(days: 6, hours: 2)),
        customerName: 'Pooja Verma',
        customerPhone: '9980123456',
        items: [
          _createItemSeed(uuid.v4(), prod6, 'Hyderabadi Dum Biryani (Chicken)', 'Biryani & Rice', 2, 340, 160),
          _createItemSeed(uuid.v4(), prod8, 'Fresh Lime Mint Soda', 'Beverages & Mocktails', 2, 110, 30),
        ],
        subtotal: 900.0,
        tax: 45.0,
        total: 945.0,
        cost: 380.0,
        paymentMode: 'upi',
      ),
      // Day -5
      _createSaleSeed(
        id: uuid.v4(),
        invoiceNumber: 'FZ-1002',
        createdAt: now.subtract(const Duration(days: 5, hours: 3)),
        customerName: 'Akash Sharma',
        customerPhone: '9845012345',
        customerId: cust1,
        items: [
          _createItemSeed(uuid.v4(), prod2, 'Chicken Tikka Kebab (6 Pcs)', 'Starters & Appetizers', 2, 320, 150),
          _createItemSeed(uuid.v4(), prod3, 'Golden Butter Chicken', 'Main Course', 1, 380, 180),
          _createItemSeed(uuid.v4(), prod5, 'Garlic Butter Naan', 'Main Course', 4, 65, 20),
        ],
        subtotal: 1280.0,
        tax: 64.0,
        total: 1344.0,
        cost: 560.0,
        paymentMode: 'card',
      ),
      // Day -4
      _createSaleSeed(
        id: uuid.v4(),
        invoiceNumber: 'FZ-1003',
        createdAt: now.subtract(const Duration(days: 4, hours: 4)),
        customerName: 'Walk-in Guest',
        items: [
          _createItemSeed(uuid.v4(), prod1, 'Crispy Paneer 65', 'Starters & Appetizers', 1, 240, 110),
          _createItemSeed(uuid.v4(), prod4, 'Paneer Butter Masala', 'Main Course', 1, 290, 130),
          _createItemSeed(uuid.v4(), prod5, 'Garlic Butter Naan', 'Main Course', 3, 65, 20),
          _createItemSeed(uuid.v4(), prod11, 'Gulab Jamun (2 Pcs)', 'Desserts', 2, 90, 30),
        ],
        subtotal: 905.0,
        tax: 45.25,
        roundOff: -0.25,
        total: 950.0,
        cost: 360.0,
        paymentMode: 'cash',
      ),
      // Day -3
      _createSaleSeed(
        id: uuid.v4(),
        invoiceNumber: 'FZ-1004',
        createdAt: now.subtract(const Duration(days: 3, hours: 5)),
        customerName: 'Karthik Raja',
        items: [
          _createItemSeed(uuid.v4(), prod7, 'Royal Mutton Biryani', 'Biryani & Rice', 3, 460, 240),
          _createItemSeed(uuid.v4(), prod9, 'Cold Brew Iced Coffee', 'Beverages & Mocktails', 3, 160, 45),
        ],
        subtotal: 1860.0,
        tax: 93.0,
        total: 1953.0,
        cost: 855.0,
        paymentMode: 'upi',
      ),
      // Day -2
      _createSaleSeed(
        id: uuid.v4(),
        invoiceNumber: 'FZ-1005',
        createdAt: now.subtract(const Duration(days: 2, hours: 1)),
        customerName: 'Meera Iyer',
        items: [
          _createItemSeed(uuid.v4(), prod6, 'Hyderabadi Dum Biryani (Chicken)', 'Biryani & Rice', 2, 340, 160),
          _createItemSeed(uuid.v4(), prod10, 'Warm Sizzling Brownie with Ice Cream', 'Desserts', 2, 190, 65),
        ],
        subtotal: 1060.0,
        tax: 53.0,
        total: 1113.0,
        cost: 450.0,
        paymentMode: 'card',
      ),
      // Day -1 (Yesterday)
      _createSaleSeed(
        id: uuid.v4(),
        invoiceNumber: 'FZ-1006',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        customerName: 'Anil Kapoor',
        items: [
          _createItemSeed(uuid.v4(), prod3, 'Golden Butter Chicken', 'Main Course', 2, 380, 180),
          _createItemSeed(uuid.v4(), prod5, 'Garlic Butter Naan', 'Main Course', 6, 65, 20),
          _createItemSeed(uuid.v4(), prod8, 'Fresh Lime Mint Soda', 'Beverages & Mocktails', 2, 110, 30),
        ],
        subtotal: 1370.0,
        tax: 68.5,
        roundOff: 0.5,
        total: 1439.0,
        cost: 540.0,
        paymentMode: 'cash',
      ),
      // Today Order 1
      _createSaleSeed(
        id: uuid.v4(),
        invoiceNumber: 'FZ-1007',
        createdAt: now.subtract(const Duration(hours: 3)),
        customerName: 'Pooja Verma',
        customerPhone: '9980123456',
        customerId: cust2,
        items: [
          _createItemSeed(uuid.v4(), prod2, 'Chicken Tikka Kebab (6 Pcs)', 'Starters & Appetizers', 1, 320, 150),
          _createItemSeed(uuid.v4(), prod6, 'Hyderabadi Dum Biryani (Chicken)', 'Biryani & Rice', 1, 340, 160),
          _createItemSeed(uuid.v4(), prod12, 'Virgin Mojito Cooler', 'Beverages & Mocktails', 1, 140, 40),
        ],
        subtotal: 800.0,
        tax: 40.0,
        total: 840.0,
        cost: 350.0,
        paymentMode: 'upi',
      ),
      // Today Order 2
      _createSaleSeed(
        id: uuid.v4(),
        invoiceNumber: 'FZ-1008',
        createdAt: now.subtract(const Duration(hours: 1)),
        customerName: 'Walk-in Table 5',
        items: [
          _createItemSeed(uuid.v4(), prod1, 'Crispy Paneer 65', 'Starters & Appetizers', 2, 240, 110),
          _createItemSeed(uuid.v4(), prod4, 'Paneer Butter Masala', 'Main Course', 2, 290, 130),
          _createItemSeed(uuid.v4(), prod5, 'Garlic Butter Naan', 'Main Course', 4, 65, 20),
          _createItemSeed(uuid.v4(), prod10, 'Warm Sizzling Brownie with Ice Cream', 'Desserts', 2, 190, 65),
        ],
        subtotal: 1700.0,
        tax: 85.0,
        total: 1785.0,
        cost: 740.0,
        paymentMode: 'cash',
      ),
    ];

    for (final saleMap in salesSeeds) {
      final items = saleMap['items'] as List<Map<String, dynamic>>;
      final saleData = Map<String, dynamic>.from(saleMap)..remove('items');
      await db.insert('sales', saleData);
      for (final item in items) {
        await db.insert('sale_items', item);
      }
    }

    // 5. Sample Expenses
    final expenses = [
      {
        'id': uuid.v4(),
        'title': 'Fresh Vegetables & Dairy Procurement',
        'category': 'Raw Materials',
        'amount': 2400.0,
        'payment_mode': 'UPI',
        'date': now.subtract(const Duration(days: 4)).toIso8601String(),
        'notes': 'Wholesale market weekly vegetables & dairy',
      },
      {
        'id': uuid.v4(),
        'title': 'Meat & Poultry Supply',
        'category': 'Raw Materials',
        'amount': 3800.0,
        'payment_mode': 'Bank Transfer',
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'notes': 'Fresh chicken and mutton bulk order',
      },
      {
        'id': uuid.v4(),
        'title': 'Commercial LPG Gas Refill (2 Cylinders)',
        'category': 'Utilities',
        'amount': 3600.0,
        'payment_mode': 'Cash',
        'date': now.subtract(const Duration(days: 5)).toIso8601String(),
        'notes': '19kg commercial cylinders',
      },
      {
        'id': uuid.v4(),
        'title': 'Kitchen Exhaust Cleaning & Servicing',
        'category': 'Maintenance',
        'amount': 1200.0,
        'payment_mode': 'Cash',
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'notes': 'Monthly exhaust duct maintenance',
      },
    ];

    for (final exp in expenses) {
      await db.insert('expenses', exp);
    }
  }

  static Map<String, dynamic> _createSaleSeed({
    required String id,
    required String invoiceNumber,
    required DateTime createdAt,
    String? customerId,
    String? customerName,
    String? customerPhone,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    double discount = 0.0,
    required double tax,
    double roundOff = 0.0,
    required double total,
    required double cost,
    required String paymentMode,
  }) {
    // Set sale_id on items
    for (final item in items) {
      item['sale_id'] = id;
    }

    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'created_at': createdAt.toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'discount_amount': discount,
      'tax_amount': tax,
      'service_charge': 0.0,
      'round_off': roundOff,
      'total_amount': total,
      'cost_total': cost,
      'payment_mode': paymentMode,
      'cash_tendered': paymentMode == 'cash' ? total : 0.0,
      'change_returned': 0.0,
      'status': 'completed',
      'payment_reference': null,
      'note': '',
      'items': items,
    };
  }

  static Map<String, dynamic> _createItemSeed(
    String id,
    String productId,
    String productName,
    String categoryName,
    double quantity,
    double unitPrice,
    double costPrice,
  ) {
    final gross = quantity * unitPrice;
    final tax = gross * 0.05;
    return {
      'id': id,
      'sale_id': '',
      'product_id': productId,
      'product_name': productName,
      'category_name': categoryName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'discount_amount': 0.0,
      'tax_amount': tax,
      'total_amount': gross,
      'note': '',
    };
  }
}
