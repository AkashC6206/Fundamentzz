import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/held_bill.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sqlite_datasource.dart';
import '../models/held_bill_model.dart';
import '../models/sale_item_model.dart';
import '../models/sale_model.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SqliteDataSource _dataSource;

  SaleRepositoryImpl(this._dataSource);

  @override
  Future<Result<String>> createSale(Sale sale) async {
    try {
      final db = await _dataSource.database;
      await db.transaction((txn) async {
        final saleModel = SaleModel.fromEntity(sale);
        await txn.insert('sales', saleModel.toMap());

        for (final item in sale.items) {
          final itemModel = SaleItemModel.fromEntity(item.copyWith(saleId: sale.id));
          await txn.insert('sale_items', itemModel.toMap());
        }
      });
      return Result.success(sale.id);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<Sale>> getSaleById(String id) async {
    try {
      final db = await _dataSource.database;
      final saleMaps = await db.query('sales', where: 'id = ?', whereArgs: [id]);
      if (saleMaps.isEmpty) {
        return const Result.error(NotFoundFailure('Sale transaction not found'));
      }

      final itemMaps = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [id]);
      final items = itemMaps.map((m) => SaleItemModel.fromMap(m)).toList();
      final sale = SaleModel.fromMap(saleMaps.first, items);
      return Result.success(sale);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Sale>>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    PaymentMode? paymentMode,
  }) async {
    try {
      final db = await _dataSource.database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startDate != null) {
        whereClause += 'created_at >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'created_at <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      if (paymentMode != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'payment_mode = ?';
        whereArgs.add(paymentMode.name);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += '(invoice_number LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ?)';
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
      }

      final List<Map<String, dynamic>> saleMaps = await db.query(
        'sales',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
      );

      final List<Sale> sales = [];
      for (final sMap in saleMaps) {
        final saleId = sMap['id'] as String;
        final itemMaps = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
        final items = itemMaps.map((m) => SaleItemModel.fromMap(m)).toList();
        sales.add(SaleModel.fromMap(sMap, items));
      }

      return Result.success(sales);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> refundSale(String id, String reason) async {
    try {
      final db = await _dataSource.database;
      await db.update(
        'sales',
        {
          'status': SaleStatus.refunded.name,
          'note': 'Refunded: $reason',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> getNextInvoiceNumber() async {
    try {
      final db = await _dataSource.database;
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sales')) ?? 0;
      final nextSeq = count + 1001;
      return Result.success('FZ-$nextSeq');
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveHeldBill(HeldBill heldBill) async {
    try {
      final db = await _dataSource.database;
      final model = HeldBillModel.fromEntity(heldBill);
      await db.insert(
        'held_bills',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<HeldBill>>> getHeldBills() async {
    try {
      final db = await _dataSource.database;
      final maps = await db.query('held_bills', orderBy: 'held_at DESC');
      final heldBills = maps.map((m) => HeldBillModel.fromMap(m)).toList();
      return Result.success(heldBills);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteHeldBill(String id) async {
    try {
      final db = await _dataSource.database;
      await db.delete('held_bills', where: 'id = ?', whereArgs: [id]);
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }
}
