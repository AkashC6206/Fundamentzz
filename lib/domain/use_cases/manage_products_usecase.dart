import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../entities/category.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class ManageProductsUseCase {
  final ProductRepository _repository;

  ManageProductsUseCase(this._repository);

  Future<Result<List<Product>>> getProducts({String? categoryId, String? searchQuery}) {
    return _repository.getProducts(categoryId: categoryId, searchQuery: searchQuery);
  }

  Future<Result<Product>> getProductById(String id) {
    return _repository.getProductById(id);
  }

  Future<Result<Product?>> getProductByBarcode(String barcode) {
    return _repository.getProductByBarcode(barcode);
  }

  Future<Result<void>> saveProduct(Product product) {
    if (product.name.trim().isEmpty) {
      return Future.value(const Result.error(ValidationFailure('Product name cannot be empty')));
    }
    if (product.sellingPrice < 0) {
      return Future.value(const Result.error(ValidationFailure('Selling price cannot be negative')));
    }
    return _repository.saveProduct(product);
  }

  Future<Result<void>> deleteProduct(String id) {
    return _repository.deleteProduct(id);
  }

  Future<Result<List<Category>>> getCategories() {
    return _repository.getCategories();
  }

  Future<Result<void>> saveCategory(Category category) {
    if (category.name.trim().isEmpty) {
      return Future.value(const Result.error(ValidationFailure('Category name cannot be empty')));
    }
    return _repository.saveCategory(category);
  }

  Future<Result<void>> deleteCategory(String id) {
    return _repository.deleteCategory(id);
  }

  Future<Result<List<Product>>> getLowStockProducts() {
    return _repository.getLowStockProducts();
  }
}
