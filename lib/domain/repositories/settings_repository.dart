import '../../core/utils/result.dart';
import '../entities/bill_customizer_settings.dart';
import '../entities/business_profile.dart';
import '../entities/tax_settings.dart';

abstract class SettingsRepository {
  Future<Result<BusinessProfile>> getBusinessProfile();
  Future<Result<void>> saveBusinessProfile(BusinessProfile profile);

  Future<Result<TaxSettings>> getTaxSettings();
  Future<Result<void>> saveTaxSettings(TaxSettings settings);

  Future<Result<void>> clearAllData();
  Future<Result<void>> loadDemoData();
  Future<Result<String>> exportBackupJson();
  Future<Result<void>> restoreBackupJson(String jsonString);

  Future<Result<Map<String, dynamic>>> getPrinterSettings();
  Future<Result<void>> savePrinterSettings({
    String? mac,
    String? name,
    String paperSize = '80mm',
    bool autoPrint = false,
  });

  Future<Result<BillCustomizerSettings>> getBillCustomizerSettings();
  Future<Result<void>> saveBillCustomizerSettings(BillCustomizerSettings settings);
}
