import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/constants/app_strings.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'domain/repositories/sale_repository.dart';
import 'presentation/providers/analytics_provider.dart';
import 'presentation/providers/billing_provider.dart';
import 'presentation/providers/expense_provider.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/sales_history_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/views/splash/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop FFI sqlite initialization
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize Dependency Injection
  await di.init();

  runApp(const FundamentzzApp());
}

class FundamentzzApp extends StatelessWidget {
  const FundamentzzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<BillingProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<InventoryProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<SalesHistoryProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<ExpenseProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<AnalyticsProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<SettingsProvider>()),
        // Provide SaleRepository for direct use in SaleDetailView
        Provider<SaleRepository>(create: (_) => di.sl<SaleRepository>()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashView(),
      ),
    );
  }
}
