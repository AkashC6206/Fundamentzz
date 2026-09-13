import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/demo_data_seeder.dart';
import '../../core/errors/failures.dart';
import '../../core/services/app_data_storage_service.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/bill_customizer_settings.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/entities/tax_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/sqlite_datasource.dart';
import '../models/business_profile_model.dart';
import '../models/tax_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SqliteDataSource _dataSource;
  final DemoDataSeeder _demoDataSeeder;
  final AppDataStorageService _appDataStorageService;

  SettingsRepositoryImpl(this._dataSource, this._demoDataSeeder, this._appDataStorageService);

  @override
  Future<Result<BusinessProfile>> getBusinessProfile() async {
    try {
      // 1. Try persistent file-based AppData first
      final appDataProfile = await _appDataStorageService.loadBusinessProfile();
      if (appDataProfile != null) {
        // Keep SQLite synchronized
        final db = await _dataSource.database;
        await db.insert(
          'business_profile',
          BusinessProfileModel.fromEntity(appDataProfile).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return Result.success(appDataProfile);
      }

      // 2. Fallback to SQLite
      final db = await _dataSource.database;
      final maps = await db.query('business_profile', where: 'id = ?', whereArgs: [1]);
      if (maps.isNotEmpty) {
        final profile = BusinessProfileModel.fromMap(maps.first);
        // Persist to AppData
        await _appDataStorageService.saveBusinessProfile(profile);
        return Result.success(profile);
      }

      // 3. Defaults
      const defaultProfile = BusinessProfile();
      await _appDataStorageService.saveBusinessProfile(defaultProfile);
      return const Result.success(defaultProfile);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveBusinessProfile(BusinessProfile profile) async {
    try {
      // Save permanently to AppData file
      await _appDataStorageService.saveBusinessProfile(profile);

      // Save to SQLite
      final db = await _dataSource.database;
      final model = BusinessProfileModel.fromEntity(profile);
      await db.insert(
        'business_profile',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<TaxSettings>> getTaxSettings() async {
    try {
      // 1. Try persistent AppData first
      final appDataTax = await _appDataStorageService.loadTaxSettings();
      if (appDataTax != null) {
        final db = await _dataSource.database;
        await db.insert(
          'tax_settings',
          TaxSettingsModel.fromEntity(appDataTax).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return Result.success(appDataTax);
      }

      // 2. Fallback to SQLite
      final db = await _dataSource.database;
      final maps = await db.query('tax_settings', where: 'id = ?', whereArgs: [1]);
      if (maps.isNotEmpty) {
        final settings = TaxSettingsModel.fromMap(maps.first);
        await _appDataStorageService.saveTaxSettings(settings);
        return Result.success(settings);
      }

      const defaultSettings = TaxSettings();
      await _appDataStorageService.saveTaxSettings(defaultSettings);
      return const Result.success(defaultSettings);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveTaxSettings(TaxSettings settings) async {
    try {
      // Save permanently to AppData file
      await _appDataStorageService.saveTaxSettings(settings);

      // Save to SQLite
      final db = await _dataSource.database;
      final model = TaxSettingsModel.fromEntity(settings);
      await db.insert(
        'tax_settings',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> clearAllData() async {
    try {
      await _dataSource.clearAll();
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> loadDemoData() async {
    try {
      await _demoDataSeeder.seedDemoData();
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> exportBackupJson() async {
    try {
      final db = await _dataSource.database;
      final categories = await db.query('categories');
      final products = await db.query('products');
      final sales = await db.query('sales');
      final saleItems = await db.query('sale_items');
      final customers = await db.query('customers');
      final customerLedger = await db.query('customer_ledger');
      final expenses = await db.query('expenses');
      final stockAdjustments = await db.query('stock_adjustments');
      final profile = await db.query('business_profile');
      final taxSettings = await db.query('tax_settings');

      final backupData = {
        'version': 1,
        'appName': 'Fundamentzz POS',
        'exportDate': DateTime.now().toIso8601String(),
        'data': {
          'categories': categories,
          'products': products,
          'sales': sales,
          'sale_items': saleItems,
          'customers': customers,
          'customer_ledger': customerLedger,
          'expenses': expenses,
          'stock_adjustments': stockAdjustments,
          'business_profile': profile,
          'tax_settings': taxSettings,
        }
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
      return Result.success(jsonStr);
    } catch (e) {
      return Result.error(BackupRestoreFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> restoreBackupJson(String jsonString) async {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      if (!decoded.containsKey('data')) {
        return const Result.error(BackupRestoreFailure('Invalid backup file structure'));
      }

      final data = decoded['data'] as Map<String, dynamic>;
      final db = await _dataSource.database;

      await db.transaction((txn) async {
        await txn.delete('sale_items');
        await txn.delete('sales');
        await txn.delete('held_bills');
        await txn.delete('customer_ledger');
        await txn.delete('customers');
        await txn.delete('expenses');
        await txn.delete('stock_adjustments');
        await txn.delete('products');
        await txn.delete('categories');

        if (data['categories'] is List) {
          for (final row in data['categories']) {
            await txn.insert('categories', Map<String, dynamic>.from(row));
          }
        }

        if (data['products'] is List) {
          for (final row in data['products']) {
            await txn.insert('products', Map<String, dynamic>.from(row));
          }
        }

        if (data['sales'] is List) {
          for (final row in data['sales']) {
            await txn.insert('sales', Map<String, dynamic>.from(row));
          }
        }

        if (data['sale_items'] is List) {
          for (final row in data['sale_items']) {
            await txn.insert('sale_items', Map<String, dynamic>.from(row));
          }
        }

        if (data['customers'] is List) {
          for (final row in data['customers']) {
            await txn.insert('customers', Map<String, dynamic>.from(row));
          }
        }

        if (data['customer_ledger'] is List) {
          for (final row in data['customer_ledger']) {
            await txn.insert('customer_ledger', Map<String, dynamic>.from(row));
          }
        }

        if (data['expenses'] is List) {
          for (final row in data['expenses']) {
            await txn.insert('expenses', Map<String, dynamic>.from(row));
          }
        }

        if (data['stock_adjustments'] is List) {
          for (final row in data['stock_adjustments']) {
            await txn.insert('stock_adjustments', Map<String, dynamic>.from(row));
          }
        }
      });

      return const Result.success(null);
    } catch (e) {
      return Result.error(BackupRestoreFailure('Failed to restore backup: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getPrinterSettings() async {
    try {
      // 1. Try AppData first
      final appDataPrinter = await _appDataStorageService.loadPrinterSettings();
      if (appDataPrinter != null) {
        await _dataSource.savePrinterSettings(
          mac: appDataPrinter['saved_mac'] as String?,
          name: appDataPrinter['saved_name'] as String?,
          paperSize: (appDataPrinter['paper_size'] as String?) ?? '80mm',
          autoPrint: ((appDataPrinter['auto_print_on_sale'] as num?)?.toInt() ?? 0) == 1,
        );
        return Result.success(appDataPrinter);
      }

      // 2. Fallback to SQLite
      final res = await _dataSource.getPrinterSettings();
      if (res != null) {
        await _appDataStorageService.savePrinterSettings(res);
        return Result.success(res);
      }

      const defaultPrinter = {
        'saved_mac': null,
        'saved_name': null,
        'paper_size': '80mm',
        'auto_print_on_sale': 0,
      };
      await _appDataStorageService.savePrinterSettings(defaultPrinter);
      return const Result.success(defaultPrinter);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> savePrinterSettings({
    String? mac,
    String? name,
    String paperSize = '80mm',
    bool autoPrint = false,
  }) async {
    try {
      final map = {
        'saved_mac': mac,
        'saved_name': name,
        'paper_size': paperSize,
        'auto_print_on_sale': autoPrint ? 1 : 0,
      };
      await _appDataStorageService.savePrinterSettings(map);
      await _dataSource.savePrinterSettings(
        mac: mac,
        name: name,
        paperSize: paperSize,
        autoPrint: autoPrint,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<BillCustomizerSettings>> getBillCustomizerSettings() async {
    try {
      // 1. Try AppData first
      final appDataCustomizer = await _appDataStorageService.loadBillCustomizerSettings();
      if (appDataCustomizer != null) {
        try {
          await _dataSource.saveBillCustomizerSettings(appDataCustomizer.toMap());
        } catch (_) {}
        return Result.success(appDataCustomizer);
      }

      // 2. Fallback to SQLite
      final res = await _dataSource.getBillCustomizerSettings();
      if (res != null) {
        final settings = BillCustomizerSettings.fromMap(res);
        await _appDataStorageService.saveBillCustomizerSettings(settings);
        return Result.success(settings);
      }

      const defaultSettings = BillCustomizerSettings();
      await _appDataStorageService.saveBillCustomizerSettings(defaultSettings);
      return const Result.success(defaultSettings);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveBillCustomizerSettings(BillCustomizerSettings settings) async {
    try {
      await _appDataStorageService.saveBillCustomizerSettings(settings);
      try {
        await _dataSource.saveBillCustomizerSettings(settings.toMap());
      } catch (dbError) {
        debugPrint('SQLite saveBillCustomizerSettings non-fatal error: $dbError');
      }
      return const Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure(e.toString()));
    }
  }
}
