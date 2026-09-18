import 'package:get_it/get_it.dart';
import '../../data/datasources/sqlite_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/use_cases/adjust_stock_usecase.dart';
import '../../domain/use_cases/backup_data_usecase.dart';
import '../../domain/use_cases/calculate_cart_total_usecase.dart';
import '../../domain/use_cases/get_analytics_usecase.dart';
import '../../domain/use_cases/manage_customers_usecase.dart';
import '../../domain/use_cases/manage_expenses_usecase.dart';
import '../../domain/use_cases/manage_products_usecase.dart';
import '../../domain/use_cases/process_sale_usecase.dart';
import '../../presentation/providers/analytics_provider.dart';
import '../../presentation/providers/billing_provider.dart';
import '../../presentation/providers/expense_provider.dart';
import '../../presentation/providers/inventory_provider.dart';
import '../../presentation/providers/sales_history_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../database/demo_data_seeder.dart';
import '../services/activation_service.dart';
import '../services/app_data_storage_service.dart';
import '../services/backup_restore_service.dart';
import '../services/bluetooth_printer_service.dart';
import '../services/image_service.dart';
import '../services/menu_transfer_service.dart';
import '../services/receipt_generator_service.dart';

final sl = GetIt.instance;

Future<void> init() => initDependencyInjection();

Future<void> initDependencyInjection() async {
  // 1. Data Source & Database
  sl.registerLazySingleton<SqliteDataSource>(() => SqliteDataSource());
  sl.registerLazySingleton<DemoDataSeeder>(() => DemoDataSeeder(sl()));

  // 2. Services
  sl.registerLazySingleton<ActivationService>(() => ActivationService());
  sl.registerLazySingleton<MenuTransferService>(() => MenuTransferService(dataSource: sl()));
  sl.registerLazySingleton<AppDataStorageService>(() => AppDataStorageService());
  sl.registerLazySingleton<ImageService>(() => ImageService());
  sl.registerLazySingleton<ReceiptGeneratorService>(() => ReceiptGeneratorService());
  sl.registerLazySingleton<BluetoothPrinterService>(() => BluetoothPrinterService());
  sl.registerLazySingleton<BackupRestoreService>(() => BackupRestoreService());

  // 3. Repositories
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(sl()));
  sl.registerLazySingleton<SaleRepository>(() => SaleRepositoryImpl(sl()));
  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl(sl()));
  sl.registerLazySingleton<ExpenseRepository>(() => ExpenseRepositoryImpl(sl()));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl(), sl(), sl()));

  // 4. Use Cases
  sl.registerLazySingleton<CalculateCartTotalUseCase>(() => CalculateCartTotalUseCase());
  sl.registerLazySingleton<ProcessSaleUseCase>(() => ProcessSaleUseCase(
        saleRepository: sl(),
        productRepository: sl(),
        customerRepository: sl(),
      ));
  sl.registerLazySingleton<ManageProductsUseCase>(() => ManageProductsUseCase(sl()));
  sl.registerLazySingleton<AdjustStockUseCase>(() => AdjustStockUseCase(sl()));
  sl.registerLazySingleton<ManageCustomersUseCase>(() => ManageCustomersUseCase(sl()));
  sl.registerLazySingleton<ManageExpensesUseCase>(() => ManageExpensesUseCase(sl()));
  sl.registerLazySingleton<GetAnalyticsUseCase>(() => GetAnalyticsUseCase(
        saleRepository: sl(),
        expenseRepository: sl(),
        productRepository: sl(),
      ));
  sl.registerLazySingleton<BackupDataUseCase>(() => BackupDataUseCase(sl()));

  // 5. Providers / ViewModels
  sl.registerFactory<BillingProvider>(() => BillingProvider(
        manageProductsUseCase: sl(),
        calculateCartTotalUseCase: sl(),
        processSaleUseCase: sl(),
        saleRepository: sl(),
        settingsRepository: sl(),
      ));
  sl.registerFactory<InventoryProvider>(() => InventoryProvider(
        manageProductsUseCase: sl(),
        adjustStockUseCase: sl(),
      ));
  sl.registerFactory<SalesHistoryProvider>(() => SalesHistoryProvider(sl()));
  sl.registerFactory<ExpenseProvider>(() => ExpenseProvider(sl()));
  sl.registerFactory<AnalyticsProvider>(() => AnalyticsProvider(sl()));
  sl.registerFactory<SettingsProvider>(() => SettingsProvider(
        backupDataUseCase: sl(),
        bluetoothPrinterService: sl(),
        backupRestoreService: sl(),
      ));
}
