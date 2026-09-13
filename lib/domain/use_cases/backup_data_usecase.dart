import '../../core/utils/result.dart';
import '../entities/bill_customizer_settings.dart';
import '../entities/business_profile.dart';
import '../entities/tax_settings.dart';
import '../repositories/settings_repository.dart';

class BackupDataUseCase {
  final SettingsRepository _settingsRepository;

  BackupDataUseCase(this._settingsRepository);

  Future<Result<String>> exportBackupJson() {
    return _settingsRepository.exportBackupJson();
  }

  Future<Result<void>> restoreBackupJson(String jsonString) {
    return _settingsRepository.restoreBackupJson(jsonString);
  }

  Future<Result<void>> resetDatabase() {
    return _settingsRepository.clearAllData();
  }

  Future<Result<void>> loadSampleData() {
    return _settingsRepository.loadDemoData();
  }

  Future<Result<BusinessProfile>> getBusinessProfile() {
    return _settingsRepository.getBusinessProfile();
  }

  Future<Result<void>> saveBusinessProfile(BusinessProfile profile) {
    return _settingsRepository.saveBusinessProfile(profile);
  }

  Future<Result<TaxSettings>> getTaxSettings() {
    return _settingsRepository.getTaxSettings();
  }

  Future<Result<void>> saveTaxSettings(TaxSettings settings) {
    return _settingsRepository.saveTaxSettings(settings);
  }

  Future<Result<Map<String, dynamic>>> getPrinterSettings() {
    return _settingsRepository.getPrinterSettings();
  }

  Future<Result<void>> savePrinterSettings({
    String? mac,
    String? name,
    String paperSize = '80mm',
    bool autoPrint = false,
  }) {
    return _settingsRepository.savePrinterSettings(
      mac: mac,
      name: name,
      paperSize: paperSize,
      autoPrint: autoPrint,
    );
  }

  Future<Result<BillCustomizerSettings>> getBillCustomizerSettings() {
    return _settingsRepository.getBillCustomizerSettings();
  }

  Future<Result<void>> saveBillCustomizerSettings(BillCustomizerSettings settings) {
    return _settingsRepository.saveBillCustomizerSettings(settings);
  }
}
