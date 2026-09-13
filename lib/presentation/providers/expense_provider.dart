import 'package:flutter/foundation.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/expense.dart';
import '../../domain/use_cases/manage_expenses_usecase.dart';

class ExpenseProvider extends ChangeNotifier {
  final ManageExpensesUseCase _manageExpensesUseCase;

  ExpenseProvider(this._manageExpensesUseCase);

  List<Expense> _expenses = [];
  List<String> _categories = [];
  String _selectedCategory = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get expenses => _expenses;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalExpenseAmount => _expenses.fold<double>(0.0, (sum, exp) => sum + exp.amount);

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await loadCategories();
    await loadExpenses();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    final res = await _manageExpensesUseCase.getCategories();
    if (res.isSuccess) {
      _categories = res.data ?? [];
    }
  }

  Future<void> loadExpenses() async {
    final res = await _manageExpensesUseCase.getExpenses(
      startDate: _startDate,
      endDate: _endDate,
      category: _selectedCategory,
    );
    if (res.isSuccess) {
      _expenses = res.data ?? [];
    } else {
      _errorMessage = res.failure?.message;
    }
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    loadExpenses();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadExpenses();
  }

  Future<Result<void>> saveExpense(Expense expense) async {
    final res = await _manageExpensesUseCase.saveExpense(expense);
    if (res.isSuccess) {
      await loadExpenses();
    }
    return res;
  }

  Future<Result<void>> deleteExpense(String id) async {
    final res = await _manageExpensesUseCase.deleteExpense(id);
    if (res.isSuccess) {
      await loadExpenses();
    }
    return res;
  }
}
