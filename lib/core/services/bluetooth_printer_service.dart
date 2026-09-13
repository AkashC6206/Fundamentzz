import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/bill_customizer_settings.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/tax_settings.dart';

enum PrinterConnectionState {
  disconnected,
  pairing,
  connecting,
  connected,
  reconnecting,
  waiting,
  error
}

class BluetoothPrinterInfo {
  final String name;
  final String address;
  final bool isPaired;
  final String paperSize; // '58mm' or '80mm'

  const BluetoothPrinterInfo({
    required this.name,
    required this.address,
    this.isPaired = false,
    this.paperSize = '58mm',
  });

  BluetoothPrinterInfo copyWith({
    String? name,
    String? address,
    bool? isPaired,
    String? paperSize,
  }) {
    return BluetoothPrinterInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      isPaired: isPaired ?? this.isPaired,
      paperSize: paperSize ?? this.paperSize,
    );
  }
}

class BluetoothPrinterService {
  static const MethodChannel _methodChannel = MethodChannel('com.fundamentzz.printer/methods');
  static const EventChannel _eventChannel = EventChannel('com.fundamentzz.printer/events');

  final StreamController<PrinterConnectionState> _connectionStateController = StreamController<PrinterConnectionState>.broadcast();
  final StreamController<List<BluetoothPrinterInfo>> _discoveredDevicesController = StreamController<List<BluetoothPrinterInfo>>.broadcast();

  BluetoothPrinterInfo? _selectedPrinter;
  bool _isScanning = false;
  String _selectedPaperSize = '58mm';
  PrinterConnectionState _currentState = PrinterConnectionState.disconnected;

  BluetoothPrinterService() {
    _initEventChannel();
  }

  void _initEventChannel() {
    if (!kIsWeb && Platform.isAndroid) {
      _eventChannel.receiveBroadcastStream().listen((eventStr) {
        try {
          final event = jsonDecode(eventStr.toString());
          final eventType = event['event'] as String;

          if (eventType == 'connection_state') {
            final stateStr = event['state'] as String;
            _currentState = _parseState(stateStr);
            _connectionStateController.add(_currentState);
          } else if (eventType == 'discovered_devices') {
             final devicesList = event['devices'] as List;
             final list = devicesList.map((d) => BluetoothPrinterInfo(
               name: d['name'] ?? 'Unknown',
               address: d['address'],
               isPaired: d['isPaired'] == true,
               paperSize: _selectedPaperSize
             )).toList();
             _discoveredDevicesController.add(list);
          } else if (eventType == 'discovery_started') {
            _isScanning = true;
          } else if (eventType == 'discovery_finished') {
            _isScanning = false;
          } else if (eventType == 'bluetooth_state_changed') {
            final enabled = event['enabled'] == true;
            if (enabled && _selectedPrinter != null && _currentState != PrinterConnectionState.connected) {
              // Bluetooth turned back on: auto-reconnect to active printer
              autoConnect(_selectedPrinter!.address, fallbackName: _selectedPrinter!.name);
            }
          }
        } catch (e) {
          debugPrint('Error parsing event: $e');
        }
      });
    }
  }

  PrinterConnectionState _parseState(String state) {
    switch (state) {
      case 'pairing': return PrinterConnectionState.pairing;
      case 'connecting': return PrinterConnectionState.connecting;
      case 'connected': return PrinterConnectionState.connected;
      case 'reconnecting': return PrinterConnectionState.reconnecting;
      case 'waiting': return PrinterConnectionState.waiting;
      case 'error': return PrinterConnectionState.error;
      default: return PrinterConnectionState.disconnected;
    }
  }

  BluetoothPrinterInfo? get selectedPrinter => _selectedPrinter;
  bool get isScanning => _isScanning;
  String get selectedPaperSize => _selectedPaperSize;
  PrinterConnectionState get connectionState => _currentState;
  Stream<PrinterConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<List<BluetoothPrinterInfo>> get discoveredDevicesStream => _discoveredDevicesController.stream;

  void setPaperSize(String size) {
    _selectedPaperSize = size;
    if (_selectedPrinter != null) {
      _selectedPrinter = _selectedPrinter!.copyWith(paperSize: size);
    }
  }

  Future<int> getAndroidSdkVersion() async {
    if (kIsWeb || !Platform.isAndroid) return 0;
    try {
      return await _methodChannel.invokeMethod<int>('getSdkVersion') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> checkPermission({bool forScan = false}) async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;
      if (Platform.isAndroid) {
        final sdkInt = await getAndroidSdkVersion();
        if (sdkInt >= 31) {
          // Android 12+ (API 31+): BLUETOOTH_CONNECT is required for RFCOMM socket connection.
          // Never check Permission.location on Android 12+ because manifest uses
          // 'neverForLocation' with maxSdkVersion="30" on location.
          final connectStatus = await Permission.bluetoothConnect.request();
          if (!connectStatus.isGranted) return false;

          if (forScan) {
            final scanStatus = await Permission.bluetoothScan.request();
            return scanStatus.isGranted;
          }
          return true;
        } else {
          // Android 11 and below (API <= 30):
          // Runtime Location permission is required for discovering nearby Bluetooth devices.
          // For connecting to a known MAC address, manifest BLUETOOTH permissions suffice.
          if (forScan) {
            final locStatus = await Permission.location.request();
            return locStatus.isGranted;
          }
          return true;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Bluetooth permission check error: $e');
      return true;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      if (kIsWeb || !Platform.isAndroid) return true;
      return await _methodChannel.invokeMethod<bool>('isBluetoothEnabled') ?? false;
    } catch (e) {
      debugPrint('Bluetooth status check error: $e');
      return true;
    }
  }

  Future<bool> enableBluetooth() async {
    try {
      if (kIsWeb || !Platform.isAndroid) return true;
      return await _methodChannel.invokeMethod<bool>('enableBluetooth') ?? false;
    } catch (e) {
      debugPrint('Bluetooth enable error: $e');
      return false;
    }
  }

  Future<void> startDiscovery() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        await enableBluetooth();
        return;
      }
      final hasPerm = await checkPermission(forScan: true);
      if (!hasPerm) return;
      await _methodChannel.invokeMethod('startDiscovery');
    } catch (e) {
      debugPrint('Bluetooth startDiscovery error: $e');
    }
  }

  Future<void> stopDiscovery() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('stopDiscovery');
    } catch (e) {
      debugPrint('Bluetooth stopDiscovery error: $e');
    }
  }

  Future<List<BluetoothPrinterInfo>> getPairedPrinters() async {
    if (kIsWeb || !Platform.isAndroid) return [];
    try {
      final jsonStr = await _methodChannel.invokeMethod<String>('getPairedPrinters');
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List;
        return list.map((d) => BluetoothPrinterInfo(
          name: d['name'] ?? 'Thermal Printer',
          address: d['address'],
          isPaired: true,
          paperSize: _selectedPaperSize,
        )).toList();
      }
    } catch (e) {
      debugPrint('getPairedPrinters error: $e');
    }
    return [];
  }

  Future<bool> pairPrinter(BluetoothPrinterInfo printer) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _methodChannel.invokeMethod<bool>('pair', {'address': printer.address}) ?? false;
    } catch (e) {
      debugPrint('pairPrinter error: $e');
      return false;
    }
  }

  Future<bool> connectPrinter(BluetoothPrinterInfo printer) async {
    try {
      final isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        await enableBluetooth();
        await Future.delayed(const Duration(milliseconds: 500));
        if (!await isBluetoothEnabled()) {
          return false;
        }
      }

      final hasPerm = await checkPermission(forScan: false);
      if (!hasPerm) return false;
      if (kIsWeb || !Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 500));
        _selectedPrinter = printer.copyWith(paperSize: _selectedPaperSize);
        _currentState = PrinterConnectionState.connected;
        _connectionStateController.add(_currentState);
        return true;
      }
      
      _selectedPrinter = printer.copyWith(paperSize: _selectedPaperSize);
      final bool connected = await _methodChannel.invokeMethod<bool>('connect', {'address': printer.address}) ?? false;
      return connected;
    } catch (e) {
      debugPrint('Bluetooth connect error: $e');
      return false;
    }
  }

  Future<void> autoConnect(String macAddress, {String fallbackName = 'Saved Printer'}) async {
     try {
        if (kIsWeb || !Platform.isAndroid) return;
        final isEnabled = await isBluetoothEnabled();
        if (!isEnabled) return; // Silent return during background autoconnect if Bluetooth is off

        final hasPerm = await checkPermission(forScan: false);
        if (!hasPerm) return;

        // Initiate connection via native manager backoff loop
        _selectedPrinter = BluetoothPrinterInfo(name: fallbackName, address: macAddress, paperSize: _selectedPaperSize);
        await _methodChannel.invokeMethod<bool>('connect', {'address': macAddress});
     } catch (e) {
        debugPrint('Bluetooth autoConnect error: $e');
     }
  }

  Future<void> disconnectPrinter() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _methodChannel.invokeMethod('disconnect');
      }
      _selectedPrinter = null;
      _currentState = PrinterConnectionState.disconnected;
      _connectionStateController.add(_currentState);
    } catch (e) {
      debugPrint('Bluetooth disconnect error: $e');
    }
  }

  Future<bool> sendTestPrint({String shopName = 'Fundamentzz Bistro & Cafe', String? paperSize}) async {
    try {
      final pSize = paperSize ?? _selectedPaperSize;
      final bytes = await generateTestReceiptBytes(shopName: shopName, paperSize: pSize);

      if (kIsWeb || !Platform.isAndroid) return true;
      return await _methodChannel.invokeMethod<bool>('write', {'bytes': Uint8List.fromList(bytes)}) ?? false;
    } catch (e) {
      debugPrint('sendTestPrint error: $e');
      return false;
    }
  }

  Future<bool> printSaleReceipt({
    required Sale sale,
    required BusinessProfile profile,
    required TaxSettings taxSettings,
    BillCustomizerSettings? customizerSettings,
    String? paperSize,
  }) async {
    try {
      final pSize = paperSize ?? _selectedPaperSize;
      final bytes = await generateSaleReceiptBytes(
        sale: sale,
        profile: profile,
        taxSettings: taxSettings,
        customizerSettings: customizerSettings,
        paperSize: pSize,
      );

      if (kIsWeb || !Platform.isAndroid) return true;
      return await _methodChannel.invokeMethod<bool>('write', {'bytes': Uint8List.fromList(bytes)}) ?? false;
    } catch (e) {
      debugPrint('printSaleReceipt error: $e');
      return false;
    }
  }

  Future<List<int>> generateTestReceiptBytes({
    required String shopName,
    String paperSize = '80mm',
  }) async {
    final profile = await CapabilityProfile.load();
    final pSize = paperSize == '58mm' ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(pSize, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.text(
      shopName.toUpperCase(),
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'THERMAL BLUETOOTH PRINTER TEST',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      DateFormatter.formatDateTime(DateTime.now()),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();
    bytes += generator.text('Print Test Successful!', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);
    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> generateSaleReceiptBytes({
    required Sale sale,
    required BusinessProfile profile,
    required TaxSettings taxSettings,
    BillCustomizerSettings? customizerSettings,
    String paperSize = '80mm',
  }) async {
    final capProfile = await CapabilityProfile.load();
    final is58mm = paperSize == '58mm';
    final pSize = is58mm ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(pSize, capProfile);
    List<int> bytes = [];

    final cfg = customizerSettings ?? const BillCustomizerSettings();
    final safeCurrency = profile.currencySymbol.contains('₹') ? 'Rs. ' : (profile.currencySymbol.isNotEmpty ? '${profile.currencySymbol} ' : '');

    bytes += generator.reset();

    // 1. Business Header
    if (cfg.showBusinessName && profile.restaurantName.isNotEmpty) {
      bytes += generator.text(
        profile.restaurantName.toUpperCase(),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    if (cfg.showTagline && profile.tagline.isNotEmpty) {
      bytes += generator.text(profile.tagline, styles: const PosStyles(align: PosAlign.center));
    }
    if (cfg.showAddress && profile.address.isNotEmpty) {
      bytes += generator.text(profile.address, styles: const PosStyles(align: PosAlign.center));
    }
    if (cfg.showPhone && profile.phone.isNotEmpty) {
      bytes += generator.text('Phone: ${profile.phone}', styles: const PosStyles(align: PosAlign.center));
    }
    if (cfg.showTaxId && profile.taxRegistrationNumber.isNotEmpty) {
      bytes += generator.text('GSTIN: ${profile.taxRegistrationNumber}', styles: const PosStyles(align: PosAlign.center));
    }
    
    if (cfg.showBusinessName || cfg.showAddress || cfg.showPhone) {
      bytes += generator.hr();
    }

    // 2. Invoice Meta Row
    if (cfg.showInvoiceNumber && cfg.showDateTime) {
      if (is58mm) {
        bytes += generator.text('Invoice: #${sale.invoiceNumber}', styles: const PosStyles(bold: true));
        bytes += generator.row([
          PosColumn(text: 'Date: ${DateFormatter.formatDate(sale.createdAt)}', width: 7),
          PosColumn(text: DateFormatter.formatTime(sale.createdAt), width: 5, styles: const PosStyles(align: PosAlign.right)),
        ]);
      } else {
        bytes += generator.row([
          PosColumn(text: 'Invoice: #${sale.invoiceNumber}', width: 6, styles: const PosStyles(bold: true)),
          PosColumn(text: DateFormatter.formatDateTime(sale.createdAt), width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    } else if (cfg.showInvoiceNumber) {
      bytes += generator.text('Invoice: #${sale.invoiceNumber}', styles: const PosStyles(bold: true));
    } else if (cfg.showDateTime) {
      if (is58mm) {
        bytes += generator.row([
          PosColumn(text: 'Date: ${DateFormatter.formatDate(sale.createdAt)}', width: 7),
          PosColumn(text: DateFormatter.formatTime(sale.createdAt), width: 5, styles: const PosStyles(align: PosAlign.right)),
        ]);
      } else {
        bytes += generator.text(DateFormatter.formatDateTime(sale.createdAt));
      }
    }

    if (cfg.showCustomerDetails && sale.customerName != null && sale.customerName!.isNotEmpty) {
      bytes += generator.text('Customer: ${sale.customerName}', styles: const PosStyles(align: PosAlign.left, bold: true));
    }
    
    if (cfg.showPaymentMode) {
      bytes += generator.text('Payment: ${sale.paymentMode.name.toUpperCase()}', styles: const PosStyles(align: PosAlign.left, bold: true));
    }

    bytes += generator.hr();

    // 3. Items Table Header
    if (is58mm) {
      bytes += generator.row([
        PosColumn(text: 'ITEM', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'QTY', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
        PosColumn(text: 'AMT', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    } else {
      if (cfg.showItemPrice) {
        bytes += generator.row([
          PosColumn(text: 'ITEM', width: 6, styles: const PosStyles(bold: true)),
          PosColumn(text: 'QTY', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
          PosColumn(text: 'PRICE', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
          PosColumn(text: 'AMOUNT', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
        ]);
      } else {
        bytes += generator.row([
          PosColumn(text: 'ITEM', width: 7, styles: const PosStyles(bold: true)),
          PosColumn(text: 'QTY', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
          PosColumn(text: 'AMOUNT', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
        ]);
      }
    }
    bytes += generator.hr();

    // 4. Items List (Regular weight for clean, compact readability)
    for (final item in sale.items) {
      final name = item.productName;
      final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(1);
      final priceStr = CurrencyFormatter.format(item.unitPrice, symbol: '');
      final totalStr = CurrencyFormatter.format(item.totalAmount, symbol: '');

      if (is58mm) {
        bytes += generator.row([
          PosColumn(text: name, width: 6),
          PosColumn(text: qtyStr, width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: totalStr, width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      } else {
        if (cfg.showItemPrice) {
          bytes += generator.row([
            PosColumn(text: name, width: 6),
            PosColumn(text: qtyStr, width: 2, styles: const PosStyles(align: PosAlign.center)),
            PosColumn(text: priceStr, width: 2, styles: const PosStyles(align: PosAlign.right)),
            PosColumn(text: totalStr, width: 2, styles: const PosStyles(align: PosAlign.right)),
          ]);
        } else {
          bytes += generator.row([
            PosColumn(text: name, width: 7),
            PosColumn(text: qtyStr, width: 2, styles: const PosStyles(align: PosAlign.center)),
            PosColumn(text: totalStr, width: 3, styles: const PosStyles(align: PosAlign.right)),
          ]);
        }
      }
    }

    bytes += generator.hr();

    // 5. Subtotal & Breakdown
    if (cfg.showSubtotal) {
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 6),
        PosColumn(text: CurrencyFormatter.format(sale.subtotal, symbol: safeCurrency), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      if (sale.discountAmount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Discount:', width: 6),
          PosColumn(text: '- ${CurrencyFormatter.format(sale.discountAmount, symbol: safeCurrency)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      if (sale.taxAmount > 0) {
        bytes += generator.row([
          PosColumn(text: '${taxSettings.taxName}:', width: 6),
          PosColumn(text: CurrencyFormatter.format(sale.taxAmount, symbol: safeCurrency), width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      bytes += generator.hr();
    }

    // 6. Grand Total (Compact bold standard size)
    if (cfg.showGrandTotal) {
      bytes += generator.row([
        PosColumn(text: 'GRAND TOTAL:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: CurrencyFormatter.format(sale.totalAmount, symbol: safeCurrency),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      bytes += generator.hr();
    }

    // 7. Cash Tendered & Change
    if (cfg.showCashChange && sale.paymentMode == PaymentMode.cash && sale.cashTendered > 0) {
      bytes += generator.row([
        PosColumn(text: 'Cash Paid:', width: 6),
        PosColumn(text: CurrencyFormatter.format(sale.cashTendered, symbol: safeCurrency), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Change Return:', width: 6),
        PosColumn(text: CurrencyFormatter.format(sale.changeReturned, symbol: safeCurrency), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr();
    }

    // 8. Footer Message (Directly under the divider without extra feed)
    if (cfg.showFooter && profile.receiptFooter.isNotEmpty) {
      bytes += generator.text(profile.receiptFooter, styles: const PosStyles(align: PosAlign.center));
    }
    
    // 9. Order Ticket / KOT
    if (cfg.showOrderTicketKot) {
      bytes += generator.feed(1);
      bytes += generator.hr(ch: '-');
      bytes += generator.text(
        '*** ORDER TICKET ***',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.row([
        PosColumn(text: 'Bill No: #${sale.invoiceNumber}', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(text: DateFormatter.formatTime(sale.createdAt), width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr(ch: '-');
      
      for (final item in sale.items) {
        final name = item.productName;
        final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(1);
        
        bytes += generator.row([
          PosColumn(text: name, width: 9),
          PosColumn(text: qtyStr, width: 3, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      bytes += generator.hr(ch: '-');
    }
    bytes += [0x1B, 0x33, 24];
  bytes += generator.text('');
  bytes += [0x1B, 0x32];
  bytes += [0x1B, 0x33, 24];
  bytes += generator.text('');
  bytes += [0x1B, 0x32];

    // Reduced trailing feed to 1 line to minimize extra white space at the end of the bill
    bytes += generator.feed(1);
    if (cfg.cutPaper) {
      bytes += generator.cut();
    }

    return bytes;
  }
}
