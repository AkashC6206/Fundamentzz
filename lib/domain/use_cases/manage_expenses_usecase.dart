import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class ManageExpensesUseCase {
  final ExpenseRepository _repository;

  ManageExpensesUseCase(this._repository);

  Future<Result<List<Expense>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) {
    return _repository.getExpenses(
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
  }

  Future<Result<void>> saveExpense(Expense expense) {
    if (expense.title.trim().isEmpty) {
      return Future.value(const Result.error(ValidationFailure('Expense title is required')));
    }
    if (expense.amount <= 0) {
      return Future.value(const Result.error(ValidationFailure('Expense amount must be greater than zero')));
    }
    return _repository.saveExpense(expense);
  }

  Future<Result<void>> deleteExpense(String id) {
    return _repository.deleteExpense(id);
  }

  Future<Result<List<String>>> getCategories() {
    return _repository.getExpenseCategories();
  }
}
