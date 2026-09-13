import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/business_profile_model.dart';
import '../../data/models/tax_settings_model.dart';
import '../../domain/entities/bill_customizer_settings.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/entities/tax_settings.dart';

/// Manages permanent, file-based AppData storage for one-time store profile
/// and user settings that persist independently of SQLite database resets.
class AppDataStorageService {
  Directory? _cachedDir;

  AppDataStorageService({Directory? customAppDataDirectory}) : _cachedDir = customAppDataDirectory;

  Future<Directory> _getAppDataDirectory() async {
    if (_cachedDir != null && await _cachedDir!.exists()) {
      return _cachedDir!;
    }

    Directory baseDir;
    if (kIsWeb) {
      baseDir = Directory('.');
    } else {
      try {
        baseDir = await getApplicationDocumentsDirectory();
      } catch (e) {
        debugPrint('Error accessing documents directory: $e');
        baseDir = await getApplicationSupportDirectory();
      }
    }

    final appDataDir = Directory(join(baseDir.path, 'appdata'));
    if (!await appDataDir.exists()) {
      await appDataDir.create(recursive: true);
    }
    _cachedDir = appDataDir;
    return appDataDir;
  }

  Future<File> _getFile(String fileName) async {
    final dir = await _getAppDataDirectory();
    return File(join(dir.path, fileName));
  }

  // --- Business Profile (One-Time Store Setup) ---

  Future<bool> isOneTimeSetupCompleted() async {
    try {
      final setupFile = await _getFile('one_time_setup.json');
      if (await setupFile.exists()) {
        final content = await setupFile.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        if (map['is_setup_completed'] == true) return true;
      }
      final profFile = await _getFile('business_profile.json');
      if (await profFile.exists()) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error reading one-time setup status: $e');
      return false;
    }
  }

  Future<void> markOneTimeSetupCompleted(bool completed) async {
    try {
      final file = await _getFile('one_time_setup.json');
      await file.writeAsString(jsonEncode({
        'is_setup_completed': completed,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      debugPrint('Error saving one-time setup status: $e');
    }
  }

  Future<BusinessProfile?> loadBusinessProfile() async {
    try {
      final file = await _getFile('business_profile.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return BusinessProfileModel.fromMap(map);
    } catch (e) {
      debugPrint('Error loading business profile from appdata: $e');
      return null;
    }
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    try {
      final file = await _getFile('business_profile.json');
      final model = BusinessProfileModel.fromEntity(profile);
      await file.writeAsString(jsonEncode(model.toMap()));
      await markOneTimeSetupCompleted(true);
    } catch (e) {
      debugPrint('Error saving business profile to appdata: $e');
    }
  }

  // --- Tax Settings ---

  Future<TaxSettings?> loadTaxSettings() async {
    try {
      final file = await _getFile('tax_settings.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return TaxSettingsModel.fromMap(map);
    } catch (e) {
      debugPrint('Error loading tax settings from appdata: $e');
      return null;
    }
  }

  Future<void> saveTaxSettings(TaxSettings settings) async {
    try {
      final file = await _getFile('tax_settings.json');
      final model = TaxSettingsModel.fromEntity(settings);
      await file.writeAsString(jsonEncode(model.toMap()));
    } catch (e) {
      debugPrint('Error saving tax settings to appdata: $e');
    }
  }

  // --- Printer Settings ---

  Future<Map<String, dynamic>?> loadPrinterSettings() async {
    try {
      final file = await _getFile('printer_settings.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading printer settings from appdata: $e');
      return null;
    }
  }

  Future<void> savePrinterSettings(Map<String, dynamic> settings) async {
    try {
      final file = await _getFile('printer_settings.json');
      await file.writeAsString(jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving printer settings to appdata: $e');
    }
  }

  // --- Bill Customizer Settings ---

  Future<BillCustomizerSettings?> loadBillCustomizerSettings() async {
    try {
      final file = await _getFile('bill_customizer.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return BillCustomizerSettings.fromMap(map);
    } catch (e) {
      debugPrint('Error loading bill customizer settings from appdata: $e');
      return null;
    }
  }

  Future<void> saveBillCustomizerSettings(BillCustomizerSettings settings) async {
    try {
      final file = await _getFile('bill_customizer.json');
      await file.writeAsString(jsonEncode(settings.toMap()));
    } catch (e) {
      debugPrint('Error saving bill customizer settings to appdata: $e');
    }
  }
}
