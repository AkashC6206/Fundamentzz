import '../../core/utils/result.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Result<List<Expense>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  });
  Future<Result<void>> saveExpense(Expense expense);
  Future<Result<void>> deleteExpense(String id);
  Future<Result<List<String>>> getExpenseCategories();
}
