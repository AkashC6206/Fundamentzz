import 'package:flutter/foundation.dart' hide Category;
import '../../core/utils/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/stock_adjustment.dart';
import '../../domain/use_cases/adjust_stock_usecase.dart';
import '../../domain/use_cases/manage_products_usecase.dart';

class InventoryProvider extends ChangeNotifier {
  final ManageProductsUseCase _manageProductsUseCase;
  final AdjustStockUseCase _adjustStockUseCase;

  InventoryProvider({
    required ManageProductsUseCase manageProductsUseCase,
    required AdjustStockUseCase adjustStockUseCase,
  })  : _manageProductsUseCase = manageProductsUseCase,
        _adjustStockUseCase = adjustStockUseCase;

  List<Product> _products = [];
  List<Category> _categories = [];
  List<StockAdjustment> _adjustmentHistory = [];
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<StockAdjustment> get adjustmentHistory => _adjustmentHistory;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalProductCount => _products.length;
  int get lowStockCount => _products.where((p) => p.isLowStock || p.isOutOfStock).length;
  double get totalStockValue => _products.fold<double>(0.0, (sum, p) => sum + (p.stockQuantity * p.sellingPrice));

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await loadCategories();
    await loadProducts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    final res = await _manageProductsUseCase.getCategories();
    if (res.isSuccess) {
      _categories = res.data ?? [];
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    final effectiveCatId = _selectedCategoryId == 'all' ? null : _selectedCategoryId;
    final res = await _manageProductsUseCase.getProducts(
      categoryId: effectiveCatId,
      searchQuery: _searchQuery,
    );
    if (res.isSuccess) {
      _products = res.data ?? [];
      _errorMessage = null;
    } else {
      _errorMessage = res.failure?.message;
    }
    notifyListeners();
  }

  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts();
  }

  void search(String query) {
    _searchQuery = query;
    loadProducts();
  }

  Future<Result<void>> saveProduct(Product product) async {
    final res = await _manageProductsUseCase.saveProduct(product);
    if (res.isSuccess) {
      await loadProducts();
    }
    return res;
  }

  Future<Result<void>> deleteProduct(String id) async {
    final res = await _manageProductsUseCase.deleteProduct(id);
    if (res.isSuccess) {
      await loadProducts();
    }
    return res;
  }

  Future<Result<void>> saveCategory(Category category) async {
    final res = await _manageProductsUseCase.saveCategory(category);
    if (res.isSuccess) {
      await loadCategories();
      await loadProducts();
    }
    return res;
  }

  Future<Result<void>> deleteCategory(String id) async {
    final res = await _manageProductsUseCase.deleteCategory(id);
    if (res.isSuccess) {
      await loadCategories();
      await loadProducts();
    }
    return res;
  }

  Future<Result<void>> adjustStock(StockAdjustment adjustment) async {
    final res = await _adjustStockUseCase.execute(adjustment);
    if (res.isSuccess) {
      await loadProducts();
    }
    return res;
  }

  Future<void> loadAdjustments({String? productId}) async {
    final res = await _adjustStockUseCase.getAdjustmentHistory(productId: productId);
    if (res.isSuccess) {
      _adjustmentHistory = res.data ?? [];
      notifyListeners();
    }
  }
}
