import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../entities/stock_adjustment.dart';
import '../repositories/product_repository.dart';

class AdjustStockUseCase {
  final ProductRepository _productRepository;

  AdjustStockUseCase(this._productRepository);

  Future<Result<void>> execute(StockAdjustment adjustment) async {
    if (adjustment.reason.trim().isEmpty) {
      return const Result.error(ValidationFailure('Adjustment reason is required'));
    }

    return _productRepository.adjustStock(adjustment);
  }

  Future<Result<List<StockAdjustment>>> getAdjustmentHistory({String? productId}) {
    return _productRepository.getStockAdjustments(productId: productId);
  }
}
