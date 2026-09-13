import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_ledger_entry.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/sqlite_datasource.dart';
import '../models/customer_ledger_entry_model.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final SqliteDataSource _dataSource;

  CustomerRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Customer>>> getCustomers({String? searchQuery}) async {
    try {
      final db = await _dataSource.database;
      String? where;
      List<dynamic>? whereArgs;

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        where = 'name LIKE ? OR phone LIKE ?';
        whereArgs = ['%$searchQuery%', '%$searchQuery%'];
      }

      final maps = await db.query('customers', where: where, whereArgs: whereArgs, orderBy: 'name ASC');
      final customers = maps.map((m) => CustomerModel.fromMap(m)).toList();
      return Result.success(customers);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<Customer>> getCustomerById(String id) async {
    try {
      final db = await _dataSource.database;
      final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) {
        return const Result.error(NotFoundFailure('Customer not found'));
      }
      return Result.success(CustomerModel.fromMap(maps.first));
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveCustomer(Customer customer) async {
    try {
      final db = await _dataSource.database;
      final model = CustomerModel.fromEntity(customer);
      await db.insert(
        'customers',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteCustomer(String id) async {
    try {
      final db = await _dataSource.database;
      await db.delete('customers', where: 'id = ?', whereArgs: [id]);
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<CustomerLedgerEntry>>> getCustomerLedger(String customerId) async {
    try {
      final db = await _dataSource.database;
      final maps = await db.query(
        'customer_ledger',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'timestamp DESC',
      );
      final entries = maps.map((m) => CustomerLedgerEntryModel.fromMap(m)).toList();
      return Result.success(entries);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> addLedgerEntry(CustomerLedgerEntry entry) async {
    try {
      final db = await _dataSource.database;
      await db.transaction((txn) async {
        final model = CustomerLedgerEntryModel.fromEntity(entry);
        await txn.insert('customer_ledger', model.toMap());

        // Update customer running balance
        await txn.update(
          'customers',
          {'credit_balance': entry.balanceAfter},
          where: 'id = ?',
          whereArgs: [entry.customerId],
        );
      });
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }
}
