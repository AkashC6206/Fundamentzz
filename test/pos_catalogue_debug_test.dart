import 'package:flutter_test/flutter_test.dart';
import 'package:fundamentzz/core/errors/failures.dart';
import 'package:fundamentzz/core/utils/result.dart';
import 'package:fundamentzz/data/datasources/sqlite_datasource.dart';
import 'package:fundamentzz/data/models/product_model.dart';
import 'package:fundamentzz/data/repositories/product_repository_impl.dart';
import 'package:fundamentzz/domain/entities/bill_customizer_settings.dart';
import 'package:fundamentzz/domain/entities/business_profile.dart';
import 'package:fundamentzz/domain/entities/category.dart';
import 'package:fundamentzz/domain/entities/customer.dart';
import 'package:fundamentzz/domain/entities/customer_ledger_entry.dart';
import 'package:fundamentzz/domain/entities/held_bill.dart';
import 'package:fundamentzz/domain/entities/product.dart';
import 'package:fundamentzz/domain/entities/stock_adjustment.dart';
import 'package:fundamentzz/domain/entities/sale.dart';
import 'package:fundamentzz/domain/entities/tax_settings.dart';
import 'package:fundamentzz/domain/repositories/customer_repository.dart';
import 'package:fundamentzz/domain/repositories/product_repository.dart';
import 'package:fundamentzz/domain/repositories/sale_repository.dart';
import 'package:fundamentzz/domain/repositories/settings_repository.dart';
import 'package:fundamentzz/domain/use_cases/calculate_cart_total_usecase.dart';
import 'package:fundamentzz/domain/use_cases/manage_products_usecase.dart';
import 'package:fundamentzz/domain/use_cases/process_sale_usecase.dart';
import 'package:fundamentzz/presentation/providers/billing_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ProductModel Safe Mapping Tests', () {
    test('ProductModel.fromMap handles string prices, bool isAvailable, and nulls safely', () {
      final rawMap = {
        'id': 'prod_99',
        'name': 'Paneer Tikka',
        'category_id': 'cat_gravy',
        'category_name': 'Gravy Special',
        'selling_price': '220.5', // String instead of num
        'cost_price': null,
        'stock_quantity': 50, // int instead of double
        'low_stock_threshold': '10',
        'unit': 'portion',
        'barcode': 'BC9900',
        'image_path': null,
        'color_value': 4280172510, // Unsigned 32-bit int
        'tax_rate': '5.0',
        'is_available': true, // bool instead of int
      };

      final model = ProductModel.fromMap(rawMap);
      expect(model.id, equals('prod_99'));
      expect(model.name, equals('Paneer Tikka'));
      expect(model.categoryId, equals('cat_gravy'));
      expect(model.categoryName, equals('Gravy Special'));
      expect(model.sellingPrice, equals(220.5));
      expect(model.costPrice, equals(0.0));
      expect(model.stockQuantity, equals(50.0));
      expect(model.lowStockThreshold, equals(10.0));
      expect(model.colorValue, equals(4280172510));
      expect(model.taxRate, equals(5.0));
      expect(model.isAvailable, isTrue);
    });

    test('ProductModel.fromMap handles is_available as 0, 1, false, string without throwing', () {
      final mapInactiveInt = {
        'id': 'p1',
        'name': 'Inactive 1',
        'category_id': 'c1',
        'selling_price': 100,
        'is_available': 0,
      };
      final modelInactiveInt = ProductModel.fromMap(mapInactiveInt);
      expect(modelInactiveInt.isAvailable, isFalse);

      final mapInactiveBool = {
        'id': 'p2',
        'name': 'Inactive 2',
        'category_id': 'c1',
        'selling_price': 100,
        'is_available': false,
      };
      final modelInactiveBool = ProductModel.fromMap(mapInactiveBool);
      expect(modelInactiveBool.isAvailable, isFalse);

      final mapActiveString = {
        'id': 'p3',
        'name': 'Active 3',
        'category_id': 'c1',
        'selling_price': 100,
        'is_available': '1',
      };
      final modelActiveString = ProductModel.fromMap(mapActiveString);
      expect(modelActiveString.isAvailable, isTrue);
    });
  });

  group('ProductRepositoryImpl & SQLite End-to-End Tests', () {
    late SqliteDataSource dataSource;
    late ProductRepositoryImpl repository;

    setUp(() async {
      dataSource = SqliteDataSource();
      final db = await dataSource.database;
      await db.delete('products');
      await db.delete('categories');
      repository = ProductRepositoryImpl(dataSource);
    });

    test('Saving product immediately appears in getProducts with "all" and null category', () async {
      const p1 = Product(
        id: 'p_butter_chicken',
        name: 'Butter Chicken',
        categoryId: 'cat_gravy',
        categoryName: 'Gravy',
        sellingPrice: 320.0,
        costPrice: 160.0,
        stockQuantity: 20.0,
        unit: 'plate',
        barcode: 'BC001',
      );

      const p2 = Product(
        id: 'p_naan',
        name: 'Butter Naan',
        categoryId: 'cat_breads',
        categoryName: 'Breads',
        sellingPrice: 40.0,
        costPrice: 15.0,
        stockQuantity: 100.0,
        unit: 'piece',
        barcode: 'BC002',
      );

      final saveRes1 = await repository.saveProduct(p1);
      expect(saveRes1.isSuccess, isTrue);
      final saveRes2 = await repository.saveProduct(p2);
      expect(saveRes2.isSuccess, isTrue);

      // 1. Query with categoryId = null (All Items)
      final allResNull = await repository.getProducts(categoryId: null);
      expect(allResNull.isSuccess, isTrue);
      expect(allResNull.data!.length, equals(2));

      // 2. Query with categoryId = 'all'
      final allResString = await repository.getProducts(categoryId: 'all');
      expect(allResString.isSuccess, isTrue);
      expect(allResString.data!.length, equals(2));

      // 3. Query with specific category 'cat_gravy'
      final gravyRes = await repository.getProducts(categoryId: 'cat_gravy');
      expect(gravyRes.isSuccess, isTrue);
      expect(gravyRes.data!.length, equals(1));
      expect(gravyRes.data!.first.name, equals('Butter Chicken'));

      // 4. Query with search query
      final searchRes = await repository.getProducts(searchQuery: 'Naan');
      expect(searchRes.isSuccess, isTrue);
      expect(searchRes.data!.length, equals(1));
      expect(searchRes.data!.first.id, equals('p_naan'));

      // 5. Query with barcode search
      final barcodeRes = await repository.getProducts(searchQuery: 'BC001');
      expect(barcodeRes.isSuccess, isTrue);
      expect(barcodeRes.data!.length, equals(1));
      expect(barcodeRes.data!.first.name, equals('Butter Chicken'));
    });
  });

  group('BillingProvider Catalogue & Error Exposure Tests', () {
    late SqliteDataSource dataSource;
    late ProductRepositoryImpl repository;
    late ManageProductsUseCase manageProductsUseCase;
    late FakeSaleRepository fakeSaleRepo;
    late FakeSettingsRepository fakeSettingsRepo;
    late BillingProvider billingProvider;

    setUp(() async {
      dataSource = SqliteDataSource();
      final db = await dataSource.database;
      await db.delete('products');
      await db.delete('categories');
      repository = ProductRepositoryImpl(dataSource);
      manageProductsUseCase = ManageProductsUseCase(repository);
      fakeSaleRepo = FakeSaleRepository();
      fakeSettingsRepo = FakeSettingsRepository();

      billingProvider = BillingProvider(
        manageProductsUseCase: manageProductsUseCase,
        calculateCartTotalUseCase: CalculateCartTotalUseCase(),
        processSaleUseCase: ProcessSaleUseCase(
          saleRepository: fakeSaleRepo,
          productRepository: repository,
          customerRepository: FakeCustomerRepository(),
        ),
        saleRepository: fakeSaleRepo,
        settingsRepository: fakeSettingsRepo,
      );
    });

    test('BillingProvider.init loads products, category filtering works, and "all" shows all items', () async {
      await repository.saveCategory(const Category(id: 'cat_gravy', name: 'Gravy'));
      await repository.saveCategory(const Category(id: 'cat_breads', name: 'Breads'));
      await repository.saveProduct(const Product(
        id: 'p1',
        name: 'Butter Chicken',
        categoryId: 'cat_gravy',
        categoryName: 'Gravy',
        sellingPrice: 300.0,
      ));
      await repository.saveProduct(const Product(
        id: 'p2',
        name: 'Garlic Naan',
        categoryId: 'cat_breads',
        categoryName: 'Breads',
        sellingPrice: 50.0,
      ));

      // Initial catalogue load
      await billingProvider.init();

      expect(billingProvider.products.length, equals(2));
      expect(billingProvider.errorMessage, isNull);
      expect(billingProvider.selectedCategoryId, equals('all'));

      // Filter by category
      billingProvider.selectCategory('cat_gravy');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(billingProvider.products.length, equals(1));
      expect(billingProvider.products.first.name, equals('Butter Chicken'));

      // Switch back to "all"
      billingProvider.selectCategory('all');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(billingProvider.products.length, equals(2));

      // Search products
      billingProvider.searchProducts('Naan');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(billingProvider.products.length, equals(1));
      expect(billingProvider.products.first.name, equals('Garlic Naan'));
    });

    test('BillingProvider exposes errorMessage instead of silently swallowing failure', () async {
      final failingUseCase = ManageProductsUseCase(FailingProductRepository());
      final failingBillingProvider = BillingProvider(
        manageProductsUseCase: failingUseCase,
        calculateCartTotalUseCase: CalculateCartTotalUseCase(),
        processSaleUseCase: ProcessSaleUseCase(
          saleRepository: fakeSaleRepo,
          productRepository: repository,
          customerRepository: FakeCustomerRepository(),
        ),
        saleRepository: fakeSaleRepo,
        settingsRepository: fakeSettingsRepo,
      );

      await failingBillingProvider.loadProducts();

      expect(failingBillingProvider.products.isEmpty, isTrue);
      expect(failingBillingProvider.errorMessage, isNotNull);
      expect(failingBillingProvider.errorMessage, contains('Simulated SQLite disk I/O error'));
    });
  });
}

class FailingProductRepository implements ProductRepository {
  @override
  Future<Result<List<Product>>> getProducts({String? categoryId, String? searchQuery}) async {
    return Future.value(const Result.error(DatabaseFailure('Simulated SQLite disk I/O error')));
  }
  @override
  Future<Result<void>> adjustStock(dynamic a) async => const Result.success(null);
  @override
  Future<Result<void>> deleteCategory(String id) async => const Result.success(null);
  @override
  Future<Result<void>> deleteProduct(String id) async => const Result.success(null);
  @override
  Future<Result<List<Category>>> getCategories() async => const Result.success([]);
  @override
  Future<Result<List<Product>>> getLowStockProducts() async => const Result.success([]);
  @override
  Future<Result<Product?>> getProductByBarcode(String b) async => const Result.success(null);
  @override
  Future<Result<Product>> getProductById(String id) async => Future.value(const Result.error(NotFoundFailure('Not found')));
  @override
  Future<Result<List<StockAdjustment>>> getStockAdjustments({String? productId}) async => const Result.success([]);
  @override
  Future<Result<void>> saveCategory(Category category) async => const Result.success(null);
  @override
  Future<Result<void>> saveProduct(Product product) async => const Result.success(null);
}

class FakeSaleRepository implements SaleRepository {
  @override
  Future<Result<String>> createSale(Sale sale) async => const Result.success('inv_1');
  @override
  Future<Result<void>> deleteHeldBill(String id) async => const Result.success(null);
  @override
  Future<Result<List<HeldBill>>> getHeldBills() async => const Result.success([]);
  @override
  Future<Result<String>> getNextInvoiceNumber() async => const Result.success('INV-001');
  @override
  Future<Result<Sale>> getSaleById(String id) async => Future.value(const Result.error(NotFoundFailure('Not found')));
  @override
  Future<Result<List<Sale>>> getSales({DateTime? startDate, DateTime? endDate, String? searchQuery, PaymentMode? paymentMode}) async => const Result.success([]);
  @override
  Future<Result<void>> refundSale(String id, String reason) async => const Result.success(null);
  @override
  Future<Result<void>> saveHeldBill(HeldBill heldBill) async => const Result.success(null);
}

class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<Result<void>> clearAllData() async => const Result.success(null);
  @override
  Future<Result<String>> exportBackupJson() async => const Result.success('{}');
  @override
  Future<Result<BillCustomizerSettings>> getBillCustomizerSettings() async => Future.value(const Result.success(BillCustomizerSettings()));
  @override
  Future<Result<BusinessProfile>> getBusinessProfile() async => Future.value(const Result.success(BusinessProfile()));
  @override
  Future<Result<Map<String, dynamic>>> getPrinterSettings() async => const Result.success({});
  @override
  Future<Result<TaxSettings>> getTaxSettings() async => Future.value(const Result.success(TaxSettings()));
  @override
  Future<Result<void>> loadDemoData() async => const Result.success(null);
  @override
  Future<Result<void>> restoreBackupJson(String jsonString) async => const Result.success(null);
  @override
  Future<Result<void>> saveBillCustomizerSettings(BillCustomizerSettings settings) async => const Result.success(null);
  @override
  Future<Result<void>> saveBusinessProfile(BusinessProfile profile) async => const Result.success(null);
  @override
  Future<Result<void>> savePrinterSettings({String? mac, String? name, String paperSize = '80mm', bool autoPrint = false}) async => const Result.success(null);
  @override
  Future<Result<void>> saveTaxSettings(TaxSettings settings) async => const Result.success(null);
}

class FakeCustomerRepository implements CustomerRepository {
  @override
  Future<Result<void>> addLedgerEntry(CustomerLedgerEntry entry) async => const Result.success(null);
  @override
  Future<Result<void>> deleteCustomer(String id) async => const Result.success(null);
  @override
  Future<Result<Customer>> getCustomerById(String id) async => Future.value(const Result.error(NotFoundFailure('Not found')));
  @override
  Future<Result<List<Customer>>> getCustomers({String? searchQuery}) async => const Result.success([]);
  @override
  Future<Result<List<CustomerLedgerEntry>>> getCustomerLedger(String customerId) async => const Result.success([]);
  @override
  Future<Result<void>> saveCustomer(Customer customer) async => const Result.success(null);
}
