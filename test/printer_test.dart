import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundamentzz/core/services/bluetooth_printer_service.dart';
import 'package:fundamentzz/domain/entities/bill_customizer_settings.dart';
import 'package:fundamentzz/domain/entities/business_profile.dart';
import 'package:fundamentzz/domain/entities/sale.dart';
import 'package:fundamentzz/domain/entities/sale_item.dart';
import 'package:fundamentzz/domain/entities/tax_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bluetooth Printer Unit Tests', () {
    test('BluetoothPrinterInfo initialization and copyWith', () {
      const printer = BluetoothPrinterInfo(
        name: 'Everycom 80mm ESC/POS Printer',
        address: '66:32:B1:4C:90:12',
        isPaired: false,
        paperSize: '80mm',
      );

      expect(printer.name, equals('Everycom 80mm ESC/POS Printer'));
      expect(printer.address, equals('66:32:B1:4C:90:12'));
      expect(printer.isPaired, isFalse);
      expect(printer.paperSize, equals('80mm'));

      final connectedPrinter = printer.copyWith(isPaired: true, paperSize: '58mm');
      expect(connectedPrinter.isPaired, isTrue);
      expect(connectedPrinter.paperSize, equals('58mm'));
      expect(connectedPrinter.name, equals(printer.name));
    });

    test('BluetoothPrinterService paper size and selection flow', () async {
      final service = BluetoothPrinterService();
      expect(service.selectedPrinter, isNull);
      expect(service.selectedPaperSize, equals('58mm'));

      service.setPaperSize('80mm');
      expect(service.selectedPaperSize, equals('80mm'));
    });

    test('BluetoothPrinterService generates ESC/POS test receipt bytes', () async {
      final service = BluetoothPrinterService();
      final bytes80 = await service.generateTestReceiptBytes(
        shopName: 'Fundamentzz Bistro',
        paperSize: '80mm',
      );
      expect(bytes80, isNotEmpty);

      final bytes58 = await service.generateTestReceiptBytes(
        shopName: 'Fundamentzz Bistro',
        paperSize: '58mm',
      );
      expect(bytes58, isNotEmpty);
    });

    test('BluetoothPrinterService generates ESC/POS sale receipt bytes with UPI QR', () async {
      final service = BluetoothPrinterService();

      final sale = Sale(
        id: 'sale_101',
        invoiceNumber: 'INV-2026-0001',
        createdAt: DateTime(2026, 8, 21, 14, 30),
        note: 'Table 4',
        customerName: 'Rohit Sharma',
        items: const [
          SaleItem(
            id: 'item_1',
            saleId: 'sale_101',
            productId: 'p_101',
            productName: 'Paneer Tikka',
            categoryName: 'Starters',
            unitPrice: 240.0,
            quantity: 2.0,
            totalAmount: 480.0,
          ),
          SaleItem(
            id: 'item_2',
            saleId: 'sale_101',
            productId: 'p_102',
            productName: 'Butter Naan',
            categoryName: 'Breads',
            unitPrice: 50.0,
            quantity: 3.0,
            totalAmount: 150.0,
          ),
        ],
        subtotal: 630.0,
        taxAmount: 31.50,
        discountAmount: 0.0,
        serviceCharge: 0.0,
        roundOff: 0.50,
        totalAmount: 662.0,
        paymentMode: PaymentMode.upi,
        status: SaleStatus.completed,
      );

      const profile = BusinessProfile(
        restaurantName: 'Fundamentzz Cafe',
        phone: '+91 98765 43210',
        upiVpa: 'fundamentzz@upi',
      );

      const taxSettings = TaxSettings(
        isTaxEnabled: true,
        defaultTaxRate: 5.0,
        taxName: 'GST',
      );

      final bytes80 = await service.generateSaleReceiptBytes(
        sale: sale,
        profile: profile,
        taxSettings: taxSettings,
        paperSize: '80mm',
      );
      expect(bytes80, isNotEmpty);

      final bytes58 = await service.generateSaleReceiptBytes(
        sale: sale,
        profile: profile,
        taxSettings: taxSettings,
        paperSize: '58mm',
      );
      expect(bytes58, isNotEmpty);
      final text58 = latin1.decode(bytes58, allowInvalid: true);
      expect(text58, contains('21 Aug 2026'));
      expect(text58, contains('02:30 PM'));
    });

    test('BillCustomizerSettings serialization, defaults, and copyWith', () {
      const defaultSettings = BillCustomizerSettings();
      expect(defaultSettings.showBusinessName, isTrue);
      expect(defaultSettings.showAddress, isTrue);
      expect(defaultSettings.showPaymentMode, isTrue);
      expect(defaultSettings.cutPaper, isTrue);

      final map = defaultSettings.toMap();
      expect(map['show_business_name'], equals(1));
      expect(map['cut_paper'], equals(1));

      final restored = BillCustomizerSettings.fromMap(map);
      expect(restored.showBusinessName, isTrue);
      expect(restored.cutPaper, isTrue);

      final customized = defaultSettings.copyWith(
        showPhone: false,
        showCustomerDetails: false,
        cutPaper: false,
      );
      expect(customized.showPhone, isFalse);
      expect(customized.showCustomerDetails, isFalse);
      expect(customized.cutPaper, isFalse);
      expect(customized.showBusinessName, isTrue);
    });

    test('BluetoothPrinterService respects BillCustomizerSettings toggles', () async {
      final service = BluetoothPrinterService();

      final sale = Sale(
        id: 'sale_102',
        invoiceNumber: 'INV-2026-0002',
        createdAt: DateTime(2026, 8, 21, 15, 0),
        items: const [
          SaleItem(
            id: 'item_1',
            saleId: 'sale_102',
            productId: 'p_101',
            productName: 'Filter Coffee',
            categoryName: 'Beverages',
            unitPrice: 40.0,
            quantity: 2.0,
            totalAmount: 80.0,
          ),
        ],
        subtotal: 80.0,
        taxAmount: 4.0,
        discountAmount: 0.0,
        serviceCharge: 0.0,
        roundOff: 0.0,
        totalAmount: 84.0,
        paymentMode: PaymentMode.cash,
        status: SaleStatus.completed,
      );

      const profile = BusinessProfile(
        restaurantName: 'Fundamentzz Quick Cafe',
        phone: '+91 98765 43210',
      );

      const taxSettings = TaxSettings(
        isTaxEnabled: true,
        defaultTaxRate: 5.0,
        taxName: 'GST',
      );

      // Customized settings with minimal toggles
      const customizer = BillCustomizerSettings(
        showBusinessName: true,
        showAddress: false,
        showPhone: false,
        showTaxId: false,
        showPaymentMode: true,
        showSubtotal: true,
        showGrandTotal: true,
        cutPaper: false,
      );

      final bytes = await service.generateSaleReceiptBytes(
        sale: sale,
        profile: profile,
        taxSettings: taxSettings,
        customizerSettings: customizer,
        paperSize: '58mm',
      );

      expect(bytes, isNotEmpty);
    });
  });
}

