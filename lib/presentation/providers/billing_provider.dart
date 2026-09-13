import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/bill_customizer_settings.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/held_bill.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/tax_settings.dart';
import '../../domain/use_cases/calculate_cart_total_usecase.dart';
import '../../domain/use_cases/manage_products_usecase.dart';
import '../../domain/use_cases/process_sale_usecase.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/settings_repository.dart';

class BillingProvider extends ChangeNotifier {
  final ManageProductsUseCase _manageProductsUseCase;
  final CalculateCartTotalUseCase _calculateCartTotalUseCase;
  final ProcessSaleUseCase _processSaleUseCase;
  final SaleRepository _saleRepository;
  final SettingsRepository _settingsRepository;

  BillingProvider({
    required ManageProductsUseCase manageProductsUseCase,
    required CalculateCartTotalUseCase calculateCartTotalUseCase,
    required ProcessSaleUseCase processSaleUseCase,
    required SaleRepository saleRepository,
    required SettingsRepository settingsRepository,
  })  : _manageProductsUseCase = manageProductsUseCase,
        _calculateCartTotalUseCase = calculateCartTotalUseCase,
        _processSaleUseCase = processSaleUseCase,
        _saleRepository = saleRepository,
        _settingsRepository = settingsRepository;

  // Catalogue State
  List<Product> _products = [];
  List<Category> _categories = [];
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Cart State
  final List<CartItem> _cartItems = [];
  double _discountPercentage = 0.0;
  double _discountFixed = 0.0;
  String _tableOrToken = 'Walk-in';
  String _orderNote = '';

  // Held Bills
  List<HeldBill> _heldBills = [];

  // Configuration
  TaxSettings _taxSettings = const TaxSettings();
  BusinessProfile _businessProfile = const BusinessProfile();
  BillCustomizerSettings _billCustomizerSettings = const BillCustomizerSettings();

  // Getters
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  double get discountPercentage => _discountPercentage;
  double get discountFixed => _discountFixed;
  String get tableOrToken => _tableOrToken;
  String get orderNote => _orderNote;
  List<HeldBill> get heldBills => _heldBills;
  TaxSettings get taxSettings => _taxSettings;
  BusinessProfile get businessProfile => _businessProfile;
  BillCustomizerSettings get billCustomizerSettings => _billCustomizerSettings;

  int get totalCartItemCount => _cartItems.fold<int>(0, (sum, item) => sum + item.quantity.toInt());

  CartCalculationResult get cartTotals {
    return _calculateCartTotalUseCase.execute(
      items: _cartItems,
      taxSettings: _taxSettings,
      discountPercentage: _discountPercentage,
      discountFixed: _discountFixed,
    );
  }

  Future<void> init() async {
    _isLoading = true;
    _searchQuery = '';
    _selectedCategoryId = 'all';
    notifyListeners();

    await loadSettings();
    await loadCategories();
    await loadProducts();
    await loadHeldBills();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    final taxRes = await _settingsRepository.getTaxSettings();
    if (taxRes.isSuccess && taxRes.data != null) {
      _taxSettings = taxRes.data!;
    }
    final profRes = await _settingsRepository.getBusinessProfile();
    if (profRes.isSuccess && profRes.data != null) {
      _businessProfile = profRes.data!;
    }
    final billRes = await _settingsRepository.getBillCustomizerSettings();
    if (billRes.isSuccess && billRes.data != null) {
      _billCustomizerSettings = billRes.data!;
    }
  }

  Future<void> loadCategories() async {
    final res = await _manageProductsUseCase.getCategories();
    if (res.isSuccess) {
      _categories = res.data ?? [];
      if (_selectedCategoryId != 'all' && !_categories.any((c) => c.id == _selectedCategoryId)) {
        _selectedCategoryId = 'all';
      }
      notifyListeners();
    }
  }

  Future<void> refreshCatalogue() async {
    if (_selectedCategoryId != 'all' && !_categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = 'all';
    }
    await loadCategories();
    await loadProducts();
  }

  Future<void> loadProducts() async {
    final effectiveCatId = _selectedCategoryId == 'all' ? null : _selectedCategoryId;
    debugPrint('[BILLING PROVIDER] Loading products (selectedCategoryId: $_selectedCategoryId, effective: $effectiveCatId, query: "$_searchQuery")');

    final res = await _manageProductsUseCase.getProducts(
      categoryId: effectiveCatId,
      searchQuery: _searchQuery,
    );
    if (res.isSuccess) {
      _products = res.data ?? [];
      _errorMessage = null;
      debugPrint('[BILLING PROVIDER] Successfully loaded ${_products.length} products');
    } else {
      _errorMessage = res.failure?.message ?? 'Failed to load products from database';
      debugPrint('[BILLING PROVIDER ERROR] Failed to load products: $_errorMessage');
    }
    notifyListeners();
  }

  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts();
  }

  void searchProducts(String query) {
    _searchQuery = query;
    loadProducts();
  }

  // Cart operations
  void addToCart(Product product, {double quantity = 1.0}) {
    if (quantity <= 0) return;
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final existingItem = _cartItems[existingIndex];
      _cartItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + quantity);
    } else {
      _cartItems.add(CartItem(
        product: product,
        quantity: quantity,
        unitPrice: product.sellingPrice,
      ));
    }
    notifyListeners();
  }

  void addMultipleToCart(Product product, double quantity, {String note = ''}) {
    if (quantity <= 0) {
      removeFromCart(product.id);
      return;
    }
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final existingItem = _cartItems[existingIndex];
      _cartItems[existingIndex] = existingItem.copyWith(
        quantity: quantity,
        note: note.isNotEmpty ? note : existingItem.note,
      );
    } else {
      _cartItems.add(CartItem(
        product: product,
        quantity: quantity,
        unitPrice: product.sellingPrice,
        note: note,
      ));
    }
    notifyListeners();
  }

  void decrementFromCart(String productId) {
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      final existingItem = _cartItems[existingIndex];
      if (existingItem.quantity > 1) {
        _cartItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity - 1);
      } else {
        _cartItems.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void addBatchToCart(Map<Product, double> batch) {
    for (final entry in batch.entries) {
      final product = entry.key;
      final quantity = entry.value;
      if (quantity <= 0) continue;

      final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        final existingItem = _cartItems[existingIndex];
        _cartItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + quantity);
      } else {
        _cartItems.add(CartItem(
          product: product,
          quantity: quantity,
          unitPrice: product.sellingPrice,
        ));
      }
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void setCartItemQuantity(Product product, double quantity) {
    if (quantity <= 0) {
      removeFromCart(product.id);
      return;
    }
    final index = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
    } else {
      _cartItems.add(CartItem(
        product: product,
        quantity: quantity,
        unitPrice: product.sellingPrice,
      ));
    }
    notifyListeners();
  }

  void updateItemDiscount(String productId, {double? percent, double? fixed}) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(
        discountPercent: percent,
        discountAmount: fixed,
      );
      notifyListeners();
    }
  }

  void updateItemNote(String productId, String note) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(note: note);
      notifyListeners();
    }
  }

  void setOverallDiscount({double? percent, double? fixed}) {
    if (percent != null) _discountPercentage = percent;
    if (fixed != null) _discountFixed = fixed;
    notifyListeners();
  }

  void setTableOrToken(String table) {
    _tableOrToken = table;
    notifyListeners();
  }

  void setOrderNote(String note) {
    _orderNote = note;
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _discountPercentage = 0.0;
    _discountFixed = 0.0;
    _tableOrToken = 'Walk-in';
    _orderNote = '';
    notifyListeners();
  }

  // Hold Bill
  Future<Result<void>> holdCurrentBill(String tableRef) async {
    if (_cartItems.isEmpty) {
      return const Result.error(ValidationFailure('Cannot hold an empty cart'));
    }

    final totals = cartTotals;
    final heldBill = HeldBill(
      id: const Uuid().v4(),
      tableOrReference: tableRef.isNotEmpty ? tableRef : _tableOrToken,
      items: List.from(_cartItems),
      totalAmount: totals.grandTotal,
      heldAt: DateTime.now(),
      note: _orderNote,
    );

    final res = await _saleRepository.saveHeldBill(heldBill);
    if (res.isSuccess) {
      clearCart();
      await loadHeldBills();
    }
    return res;
  }

  Future<void> loadHeldBills() async {
    final res = await _saleRepository.getHeldBills();
    if (res.isSuccess) {
      _heldBills = res.data ?? [];
      notifyListeners();
    }
  }

  Future<void> resumeHeldBill(HeldBill bill) async {
    _cartItems.clear();
    _cartItems.addAll(bill.items);
    _tableOrToken = bill.tableOrReference;
    _orderNote = bill.note;
    await _saleRepository.deleteHeldBill(bill.id);
    await loadHeldBills();
    notifyListeners();
  }

  Future<void> discardHeldBill(String id) async {
    await _saleRepository.deleteHeldBill(id);
    await loadHeldBills();
  }

  // Checkout & Payment Processing
  Future<Result<Sale>> processCheckout({
    required PaymentMode paymentMode,
    double cashTendered = 0.0,
    double changeReturned = 0.0,
    String? paymentRef,
  }) async {
    if (_cartItems.isEmpty) {
      return const Result.error(ValidationFailure('Cart is empty'));
    }

    final totals = cartTotals;
    final invRes = await _saleRepository.getNextInvoiceNumber();
    final invoiceNumber = invRes.isSuccess ? (invRes.data ?? 'FZ-1001') : 'FZ-1001';
    final saleId = const Uuid().v4();

    final saleItems = _cartItems.map((c) {
      return SaleItem(
        id: const Uuid().v4(),
        saleId: saleId,
        productId: c.product.id,
        productName: c.product.name,
        categoryName: c.product.categoryName,
        quantity: c.quantity,
        unitPrice: c.unitPrice,
        costPrice: c.product.costPrice,
        discountAmount: c.effectiveDiscount,
        taxAmount: c.taxAmount,
        totalAmount: c.netTotal,
        note: c.note,
      );
    }).toList();

    final sale = Sale(
      id: saleId,
      invoiceNumber: invoiceNumber,
      createdAt: DateTime.now(),
      items: saleItems,
      subtotal: totals.subtotal,
      discountAmount: totals.totalDiscount,
      taxAmount: totals.taxAmount,
      serviceCharge: totals.serviceCharge,
      roundOff: totals.roundOff,
      totalAmount: totals.grandTotal,
      costTotal: totals.totalCost,
      paymentMode: paymentMode,
      cashTendered: cashTendered > 0 ? cashTendered : totals.grandTotal,
      changeReturned: changeReturned,
      status: SaleStatus.completed,
      paymentReference: paymentRef,
      note: _tableOrToken != 'Walk-in' ? '$_tableOrToken ${_orderNote.isNotEmpty ? '• $_orderNote' : ''}'.trim() : _orderNote,
    );

    final res = await _processSaleUseCase.execute(sale);
    if (res.isSuccess) {
      clearCart();
      await loadProducts(); // Refresh stock levels in catalogue
    }
    return res;
  }
}
