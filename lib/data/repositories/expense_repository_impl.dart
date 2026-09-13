import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/sqlite_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final SqliteDataSource _dataSource;

  ExpenseRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Expense>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      final db = await _dataSource.database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startDate != null) {
        whereClause += 'date >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'date <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      if (category != null && category.isNotEmpty && category != 'all') {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'category = ?';
        whereArgs.add(category);
      }

      final maps = await db.query(
        'expenses',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'date DESC',
      );

      final expenses = maps.map((m) => ExpenseModel.fromMap(m)).toList();
      return Result.success(expenses);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveExpense(Expense expense) async {
    try {
      final db = await _dataSource.database;
      final model = ExpenseModel.fromEntity(expense);
      await db.insert(
        'expenses',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteExpense(String id) async {
    try {
      final db = await _dataSource.database;
      await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getExpenseCategories() async {
    return const Result.success([
      'Raw Materials',
      'Rent',
      'Utilities',
      'Staff Salary',
      'Maintenance',
      'Marketing',
      'Packaging',
      'Other',
    ]);
  }
}
