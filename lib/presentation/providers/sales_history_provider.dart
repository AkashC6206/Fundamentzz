import 'package:flutter/foundation.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

class SalesHistoryProvider extends ChangeNotifier {
  final SaleRepository _saleRepository;

  SalesHistoryProvider(this._saleRepository);

  List<Sale> _sales = [];
  PaymentMode? _filterPaymentMode;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<Sale> get sales => _sales;
  PaymentMode? get filterPaymentMode => _filterPaymentMode;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalFilteredSales => _sales.where((s) => s.status == SaleStatus.completed).fold<double>(0.0, (sum, s) => sum + s.totalAmount);
  int get totalCompletedCount => _sales.where((s) => s.status == SaleStatus.completed).length;

  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();

    final res = await _saleRepository.getSales(
      startDate: _startDate,
      endDate: _endDate,
      paymentMode: _filterPaymentMode,
      searchQuery: _searchQuery,
    );

    if (res.isSuccess) {
      _sales = res.data ?? [];
    } else {
      _errorMessage = res.failure?.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFilterPaymentMode(PaymentMode? mode) {
    _filterPaymentMode = mode;
    loadSales();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadSales();
  }

  void search(String query) {
    _searchQuery = query;
    loadSales();
  }

  Future<Result<void>> refundSale(String id, String reason) async {
    final res = await _saleRepository.refundSale(id, reason);
    if (res.isSuccess) {
      await loadSales();
    }
    return res;
  }
}
