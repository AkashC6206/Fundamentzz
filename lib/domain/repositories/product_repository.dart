import '../../core/utils/result.dart';
import '../entities/category.dart';
import '../entities/product.dart';
import '../entities/stock_adjustment.dart';

abstract class ProductRepository {
  Future<Result<List<Product>>> getProducts({String? categoryId, String? searchQuery});
  Future<Result<Product>> getProductById(String id);
  Future<Result<Product?>> getProductByBarcode(String barcode);
  Future<Result<void>> saveProduct(Product product);
  Future<Result<void>> deleteProduct(String id);

  Future<Result<List<Category>>> getCategories();
  Future<Result<void>> saveCategory(Category category);
  Future<Result<void>> deleteCategory(String id);

  Future<Result<void>> adjustStock(StockAdjustment adjustment);
  Future<Result<List<StockAdjustment>>> getStockAdjustments({String? productId});
  Future<Result<List<Product>>> getLowStockProducts();
}
