import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundamentzz/core/services/app_data_storage_service.dart';
import 'package:fundamentzz/domain/entities/bill_customizer_settings.dart';
import 'package:fundamentzz/domain/entities/business_profile.dart';
import 'package:fundamentzz/domain/entities/tax_settings.dart';

void main() {
  group('AppDataStorageService Unit Tests', () {
    late Directory tempDir;
    late AppDataStorageService storageService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('appdata_test_');
      storageService = AppDataStorageService(customAppDataDirectory: tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('isOneTimeSetupCompleted returns false initially', () async {
      final isDone = await storageService.isOneTimeSetupCompleted();
      expect(isDone, false);
    });

    test('markOneTimeSetupCompleted updates setup flag properly', () async {
      await storageService.markOneTimeSetupCompleted(true);
      final isDone = await storageService.isOneTimeSetupCompleted();
      expect(isDone, true);
    });

    test('saves and loads BusinessProfile from permanent AppData file', () async {
      const profile = BusinessProfile(
        restaurantName: 'Grand Spice Kitchen',
        tagline: 'Authentic Indian Flavours',
        address: '42 Brigade Road, Bangalore',
        phone: '+91 99887 76655',
        email: 'info@grandspice.in',
        taxRegistrationNumber: '29ABCDE9999Z1Z8',
        currencySymbol: '₹',
        upiVpa: 'grandspice@upi',
        receiptFooter: 'Visit us again soon!',
      );

      await storageService.saveBusinessProfile(profile);

      // BusinessProfile save also automatically marks one-time setup as completed
      expect(await storageService.isOneTimeSetupCompleted(), true);

      final loaded = await storageService.loadBusinessProfile();
      expect(loaded, isNotNull);
      expect(loaded!.restaurantName, 'Grand Spice Kitchen');
      expect(loaded.tagline, 'Authentic Indian Flavours');
      expect(loaded.address, '42 Brigade Road, Bangalore');
      expect(loaded.phone, '+91 99887 76655');
      expect(loaded.taxRegistrationNumber, '29ABCDE9999Z1Z8');
      expect(loaded.upiVpa, 'grandspice@upi');
      expect(loaded.receiptFooter, 'Visit us again soon!');
    });

    test('saves and loads TaxSettings from AppData', () async {
      const tax = TaxSettings(
        isTaxEnabled: true,
        isTaxInclusive: true,
        taxName: 'VAT',
        defaultTaxRate: 18.0,
        isServiceChargeEnabled: true,
        serviceChargeRate: 5.0,
        isRoundOffEnabled: true,
      );

      await storageService.saveTaxSettings(tax);

      final loaded = await storageService.loadTaxSettings();
      expect(loaded, isNotNull);
      expect(loaded!.isTaxEnabled, true);
      expect(loaded.isTaxInclusive, true);
      expect(loaded.taxName, 'VAT');
      expect(loaded.defaultTaxRate, 18.0);
      expect(loaded.isServiceChargeEnabled, true);
      expect(loaded.serviceChargeRate, 5.0);
      expect(loaded.isRoundOffEnabled, true);
    });

    test('saves and loads PrinterSettings from AppData', () async {
      final printer = {
        'saved_mac': '00:11:22:33:44:55',
        'saved_name': 'Thermal 80mm POS',
        'paper_size': '80mm',
        'auto_print_on_sale': 1,
      };

      await storageService.savePrinterSettings(printer);

      final loaded = await storageService.loadPrinterSettings();
      expect(loaded, isNotNull);
      expect(loaded!['saved_mac'], '00:11:22:33:44:55');
      expect(loaded['saved_name'], 'Thermal 80mm POS');
      expect(loaded['paper_size'], '80mm');
      expect(loaded['auto_print_on_sale'], 1);
    });

    test('saves and loads BillCustomizerSettings from AppData', () async {
      const customizer = BillCustomizerSettings(
        showBusinessName: true,
        showTagline: false,
        showAddress: true,
        showPhone: true,
        showTaxId: false,
        showInvoiceNumber: true,
        showDateTime: true,
        showCustomerDetails: false,
        showPaymentMode: true,
        showItemPrice: true,
        showSubtotal: true,
        showGrandTotal: true,
        showCashChange: true,
        showFooter: false,
        showOrderTicketKot: false,
        cutPaper: true,
      );

      await storageService.saveBillCustomizerSettings(customizer);

      final loaded = await storageService.loadBillCustomizerSettings();
      expect(loaded, isNotNull);
      expect(loaded!.showBusinessName, true);
      expect(loaded.showTagline, false);
      expect(loaded.showAddress, true);
      expect(loaded.showTaxId, false);
      expect(loaded.showFooter, false);
      expect(loaded.cutPaper, true);
    });
  });
}
