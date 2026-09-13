import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/services/backup_restore_service.dart';
import '../../core/services/bluetooth_printer_service.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/bill_customizer_settings.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/tax_settings.dart';
import '../../domain/use_cases/backup_data_usecase.dart';

class SettingsProvider extends ChangeNotifier {
  final BackupDataUseCase _backupDataUseCase;
  final BluetoothPrinterService _bluetoothPrinterService;
  final BackupRestoreService _backupRestoreService;
  
  StreamSubscription? _devicesSub;
  StreamSubscription? _connectionSub;

  SettingsProvider({
    required BackupDataUseCase backupDataUseCase,
    required BluetoothPrinterService bluetoothPrinterService,
    required BackupRestoreService backupRestoreService,
  })  : _backupDataUseCase = backupDataUseCase,
        _bluetoothPrinterService = bluetoothPrinterService,
        _backupRestoreService = backupRestoreService {
    
    _devicesSub = _bluetoothPrinterService.discoveredDevicesStream.listen((devices) {
      _discoveredPrinters = devices;
      notifyListeners();
    });
    
    _connectionSub = _bluetoothPrinterService.connectionStateStream.listen((state) {
      notifyListeners();
    });
  }

  BusinessProfile _businessProfile = const BusinessProfile();
  TaxSettings _taxSettings = const TaxSettings();
  BillCustomizerSettings _billCustomizerSettings = const BillCustomizerSettings();
  List<BluetoothPrinterInfo> _discoveredPrinters = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _savedPrinterMac;
  String? _savedPrinterName;
  String _selectedPaperSize = '80mm';
  bool _autoPrintOnSale = false;

  BusinessProfile get businessProfile => _businessProfile;
  TaxSettings get taxSettings => _taxSettings;
  BillCustomizerSettings get billCustomizerSettings => _billCustomizerSettings;
  List<BluetoothPrinterInfo> get discoveredPrinters => _discoveredPrinters;
  BluetoothPrinterInfo? get selectedPrinter => _bluetoothPrinterService.selectedPrinter;
  bool get isScanningPrinters => _bluetoothPrinterService.isScanning;
  PrinterConnectionState get connectionState => _bluetoothPrinterService.connectionState;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get savedPrinterMac => _savedPrinterMac;
  String? get savedPrinterName => _savedPrinterName;
  String get selectedPaperSize => _selectedPaperSize;
  bool get autoPrintOnSale => _autoPrintOnSale;

  @override
  void dispose() {
    _devicesSub?.cancel();
    _connectionSub?.cancel();
    super.dispose();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final profRes = await _backupDataUseCase.getBusinessProfile();
    if (profRes.isSuccess && profRes.data != null) {
      _businessProfile = profRes.data!;
    }

    final taxRes = await _backupDataUseCase.getTaxSettings();
    if (taxRes.isSuccess && taxRes.data != null) {
      _taxSettings = taxRes.data!;
    }

    final billRes = await _backupDataUseCase.getBillCustomizerSettings();
    if (billRes.isSuccess && billRes.data != null) {
      _billCustomizerSettings = billRes.data!;
    }

    final printerRes = await _backupDataUseCase.getPrinterSettings();
    if (printerRes.isSuccess && printerRes.data != null) {
      final pData = printerRes.data!;
      _savedPrinterMac = pData['saved_mac'] as String?;
      _savedPrinterName = pData['saved_name'] as String?;
      _selectedPaperSize = (pData['paper_size'] as String?) ?? '80mm';
      _autoPrintOnSale = ((pData['auto_print_on_sale'] as num?)?.toInt() ?? 0) == 1;
      _bluetoothPrinterService.setPaperSize(_selectedPaperSize);
    }

    _isLoading = false;
    notifyListeners();

    // Auto-connect to saved printer if available
    if (_savedPrinterMac != null && _savedPrinterMac!.isNotEmpty) {
      _bluetoothPrinterService.autoConnect(_savedPrinterMac!, fallbackName: _savedPrinterName ?? 'Saved Printer');
    }
  }

  Future<Result<void>> saveProfile(BusinessProfile profile) async {
    final res = await _backupDataUseCase.saveBusinessProfile(profile);
    if (res.isSuccess) {
      _businessProfile = profile;
      notifyListeners();
    }
    return res;
  }

  Future<Result<void>> saveTaxSettings(TaxSettings settings) async {
    final res = await _backupDataUseCase.saveTaxSettings(settings);
    if (res.isSuccess) {
      _taxSettings = settings;
      notifyListeners();
    }
    return res;
  }

  Future<Result<String>> exportAndShareBackup() async {
    final jsonRes = await _backupDataUseCase.exportBackupJson();
    if (!jsonRes.isSuccess || jsonRes.data == null) {
      return Result.error(jsonRes.failure);
    }
    return await _backupRestoreService.saveAndShareBackup(jsonRes.data!);
  }

  Future<Result<void>> restoreBackupJson(String jsonString) async {
    final res = await _backupDataUseCase.restoreBackupJson(jsonString);
    if (res.isSuccess) {
      await init();
    }
    return res;
  }

  Future<Result<void>> loadSampleData() async {
    final res = await _backupDataUseCase.loadSampleData();
    if (res.isSuccess) {
      await init();
    }
    return res;
  }

  Future<Result<void>> resetDatabase() async {
    final res = await _backupDataUseCase.resetDatabase();
    if (res.isSuccess) {
      await init();
    }
    return res;
  }

  // Bluetooth Printer actions
  Future<void> scanPrinters() async {
    await _bluetoothPrinterService.startDiscovery();
    notifyListeners();
  }

  Future<void> stopScanning() async {
    await _bluetoothPrinterService.stopDiscovery();
    notifyListeners();
  }

  Future<bool> isBluetoothEnabled() async {
    return await _bluetoothPrinterService.isBluetoothEnabled();
  }

  Future<bool> enableBluetooth() async {
    return await _bluetoothPrinterService.enableBluetooth();
  }

  Future<void> refreshPrinters() async {
    final paired = await _bluetoothPrinterService.getPairedPrinters();
    _discoveredPrinters = paired;
    notifyListeners();
    await _bluetoothPrinterService.startDiscovery();
  }

  Future<bool> connectPrinter(BluetoothPrinterInfo printer) async {
    final connected = await _bluetoothPrinterService.connectPrinter(printer);
    if (connected) {
      _savedPrinterMac = printer.address;
      _savedPrinterName = printer.name;
      await _backupDataUseCase.savePrinterSettings(
        mac: _savedPrinterMac,
        name: _savedPrinterName,
        paperSize: _selectedPaperSize,
        autoPrint: _autoPrintOnSale,
      );
    }
    notifyListeners();
    return connected;
  }
  
  Future<bool> pairPrinter(BluetoothPrinterInfo printer) async {
    return await _bluetoothPrinterService.pairPrinter(printer);
  }

  Future<void> disconnectPrinter() async {
    await _bluetoothPrinterService.disconnectPrinter();
    _savedPrinterMac = null;
    _savedPrinterName = null;
    await _backupDataUseCase.savePrinterSettings(
      mac: null,
      name: null,
      paperSize: _selectedPaperSize,
      autoPrint: _autoPrintOnSale,
    );
    notifyListeners();
  }

  Future<void> setPaperSize(String size) async {
    _selectedPaperSize = size;
    _bluetoothPrinterService.setPaperSize(size);
    await _backupDataUseCase.savePrinterSettings(
      mac: _savedPrinterMac,
      name: _savedPrinterName,
      paperSize: size,
      autoPrint: _autoPrintOnSale,
    );
    notifyListeners();
  }

  Future<void> setAutoPrintOnSale(bool autoPrint) async {
    _autoPrintOnSale = autoPrint;
    await _backupDataUseCase.savePrinterSettings(
      mac: _savedPrinterMac,
      name: _savedPrinterName,
      paperSize: _selectedPaperSize,
      autoPrint: autoPrint,
    );
    notifyListeners();
  }

  Future<void> openSystemBluetoothSettings() async {
    try {
      const channel = MethodChannel('com.fundamentzz.fundamentzz/settings');
      await channel.invokeMethod('openBluetoothSettings');
    } catch (e) {
      debugPrint('Open Bluetooth settings error: $e');
    }
  }

  Future<Result<void>> updateBillCustomizerSettings(BillCustomizerSettings settings) async {
    _billCustomizerSettings = settings;
    notifyListeners();
    final res = await _backupDataUseCase.saveBillCustomizerSettings(settings);
    return res;
  }

  Future<bool> testPrint() async {
    return await _bluetoothPrinterService.sendTestPrint(
      shopName: _businessProfile.restaurantName,
      paperSize: _selectedPaperSize,
    );
  }

  Future<bool> printSaleReceipt(Sale sale) async {
    return await _bluetoothPrinterService.printSaleReceipt(
      sale: sale,
      profile: _businessProfile,
      taxSettings: _taxSettings,
      customizerSettings: _billCustomizerSettings,
      paperSize: _selectedPaperSize,
    );
  }
}
