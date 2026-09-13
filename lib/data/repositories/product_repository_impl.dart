import 'package:flutter/foundation.dart' hide Category;
import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/stock_adjustment.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/sqlite_datasource.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/stock_adjustment_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final SqliteDataSource _dataSource;

  ProductRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Product>>> getProducts({String? categoryId, String? searchQuery}) async {
    try {
      final db = await _dataSource.database;

      final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final totalDbCount = (countRes.firstOrNull?['count'] as num?)?.toInt() ?? 0;
      debugPrint('[DATABASE] Total products in database: $totalDbCount');
      debugPrint('[REPOSITORY] getProducts called with categoryId: $categoryId, searchQuery: "$searchQuery"');

      String whereClause = '';
      List<dynamic> whereArgs = [];

      final isAll = categoryId == null || categoryId.trim().isEmpty || categoryId.trim().toLowerCase() == 'all';
      if (!isAll) {
        whereClause += 'category_id = ?';
        whereArgs.add(categoryId);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryPattern = '%${searchQuery.trim()}%';
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += '(name LIKE ? OR barcode LIKE ?)';
        whereArgs.add(queryPattern);
        whereArgs.add(queryPattern);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'name ASC',
      );
      debugPrint('[REPOSITORY] Query returned ${maps.length} rows from products table (where: "$whereClause", args: $whereArgs)');

      final products = maps.map((map) => ProductModel.fromMap(map)).toList();
      return Result.success(products);
    } catch (e, stack) {
      debugPrint('[REPOSITORY ERROR] getProducts failed: $e\n$stack');
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<Product>> getProductById(String id) async {
    try {
      final db = await _dataSource.database;
      final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) {
        return const Result.error(NotFoundFailure('Product not found'));
      }
      return Result.success(ProductModel.fromMap(maps.first));
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<Product?>> getProductByBarcode(String barcode) async {
    try {
      if (barcode.trim().isEmpty) return const Result.success(null);
      final db = await _dataSource.database;
      final maps = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
      if (maps.isEmpty) {
        return const Result.success(null);
      }
      return Result.success(ProductModel.fromMap(maps.first));
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveProduct(Product product) async {
    try {
      final db = await _dataSource.database;
      final model = ProductModel.fromEntity(product);
      debugPrint('[REPOSITORY] Saving product to SQLite: id=${product.id}, name="${product.name}", categoryId=${product.categoryId}');
      await db.insert(
        'products',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[REPOSITORY] Product successfully written to SQLite products table: ${product.name}');
      return const Result.success(null);
    } catch (e, stack) {
      debugPrint('[REPOSITORY ERROR] saveProduct failed: $e\n$stack');
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProduct(String id) async {
    try {
      final db = await _dataSource.database;
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      await _dataSource.cleanupUnusedDefaultCategories();
      final db = await _dataSource.database;
      final maps = await db.query('categories', orderBy: 'name ASC');
      final categories = maps.map((map) => CategoryModel.fromMap(map)).toList();
      return Result.success(categories);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveCategory(Category category) async {
    try {
      final db = await _dataSource.database;
      final model = CategoryModel.fromEntity(category);
      await db.insert(
        'categories',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteCategory(String id) async {
    try {
      final db = await _dataSource.database;
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> adjustStock(StockAdjustment adjustment) async {
    try {
      final db = await _dataSource.database;
      await db.transaction((txn) async {
        // 1. Insert adjustment audit log
        final adjModel = StockAdjustmentModel.fromEntity(adjustment);
        await txn.insert('stock_adjustments', adjModel.toMap());

        // 2. Update product current stock
        await txn.update(
          'products',
          {'stock_quantity': adjustment.newStockQuantity},
          where: 'id = ?',
          whereArgs: [adjustment.productId],
        );
      });
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<StockAdjustment>>> getStockAdjustments({String? productId}) async {
    try {
      final db = await _dataSource.database;
      final maps = await db.query(
        'stock_adjustments',
        where: productId != null ? 'product_id = ?' : null,
        whereArgs: productId != null ? [productId] : null,
        orderBy: 'timestamp DESC',
      );
      final adjustments = maps.map((m) => StockAdjustmentModel.fromMap(m)).toList();
      return Result.success(adjustments);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Product>>> getLowStockProducts() async {
    try {
      final db = await _dataSource.database;
      final maps = await db.query(
        'products',
        where: 'stock_quantity <= low_stock_threshold',
        orderBy: 'stock_quantity ASC',
      );
      final products = maps.map((m) => ProductModel.fromMap(m)).toList();
      return Result.success(products);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }
}
