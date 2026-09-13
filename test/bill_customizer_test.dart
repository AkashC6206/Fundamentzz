import 'package:flutter_test/flutter_test.dart';
import 'package:fundamentzz/core/services/receipt_generator_service.dart';
import 'package:fundamentzz/data/datasources/sqlite_datasource.dart';
import 'package:fundamentzz/domain/entities/bill_customizer_settings.dart';
import 'package:fundamentzz/domain/entities/business_profile.dart';
import 'package:fundamentzz/domain/entities/sale.dart';
import 'package:fundamentzz/domain/entities/sale_item.dart';
import 'package:fundamentzz/domain/entities/tax_settings.dart';

void main() {
  group('BillCustomizerSettings Unit Tests', () {
    test('default settings have all toggles enabled', () {
      const cfg = BillCustomizerSettings();
      expect(cfg.showBusinessName, isTrue);
      expect(cfg.showTagline, isTrue);
      expect(cfg.showAddress, isTrue);
      expect(cfg.showPhone, isTrue);
      expect(cfg.showTaxId, isTrue);
      expect(cfg.showInvoiceNumber, isTrue);
      expect(cfg.showDateTime, isTrue);
      expect(cfg.showCustomerDetails, isTrue);
      expect(cfg.showPaymentMode, isTrue);
      expect(cfg.showItemPrice, isTrue);
      expect(cfg.showSubtotal, isTrue);
      expect(cfg.showGrandTotal, isTrue);
      expect(cfg.showCashChange, isTrue);
      expect(cfg.showFooter, isTrue);
      expect(cfg.showOrderTicketKot, isTrue);
      expect(cfg.cutPaper, isTrue);
    });

    test('copyWith properly updates selective flags', () {
      const original = BillCustomizerSettings();
      final updated = original.copyWith(
        showPhone: false,
        showTagline: false,
        showItemPrice: false,
        showOrderTicketKot: false,
      );

      expect(updated.showPhone, isFalse);
      expect(updated.showTagline, isFalse);
      expect(updated.showItemPrice, isFalse);
      expect(updated.showOrderTicketKot, isFalse);
      expect(updated.showBusinessName, isTrue);
      expect(updated.showGrandTotal, isTrue);
    });

    test('fromMap safely parses ints, bools, nums, strings, and nulls without throwing', () {
      // Map with mixed types (like raw JSON or sqlite)
      final map = {
        'show_business_name': 1,
        'show_tagline': 0,
        'show_address': true,
        'show_phone': false,
        'show_tax_id': 'true',
        'show_invoice_number': '0',
        'show_date_time': null, // should fallback to default true
        'show_customer_details': 1,
        'show_payment_mode': 0,
        'show_item_price': false,
        'show_subtotal': true,
        'show_grand_total': 1,
        'show_cash_change': 0,
        'show_footer': null,
        'show_order_ticket_kot': false,
        'cut_paper': 1,
      };

      final parsed = BillCustomizerSettings.fromMap(map);
      expect(parsed.showBusinessName, isTrue);
      expect(parsed.showTagline, isFalse);
      expect(parsed.showAddress, isTrue);
      expect(parsed.showPhone, isFalse);
      expect(parsed.showTaxId, isTrue);
      expect(parsed.showInvoiceNumber, isFalse);
      expect(parsed.showDateTime, isTrue);
      expect(parsed.showCustomerDetails, isTrue);
      expect(parsed.showPaymentMode, isFalse);
      expect(parsed.showItemPrice, isFalse);
      expect(parsed.showSubtotal, isTrue);
      expect(parsed.showGrandTotal, isTrue);
      expect(parsed.showCashChange, isFalse);
      expect(parsed.showFooter, isTrue);
      expect(parsed.showOrderTicketKot, isFalse);
      expect(parsed.cutPaper, isTrue);
    });
  });

  group('ReceiptGeneratorService Customization Tests', () {
    late Sale sampleSale;
    late BusinessProfile sampleProfile;
    late TaxSettings sampleTax;

    setUp(() {
      sampleSale = Sale(
        id: 'sale_custom_01',
        invoiceNumber: 'INV-9999',
        createdAt: DateTime(2026, 9, 11, 14, 30),
        customerName: 'Aarav Patel',
        subtotal: 500.0,
        taxAmount: 25.0,
        totalAmount: 525.0,
        paymentMode: PaymentMode.cash,
        cashTendered: 600.0,
        changeReturned: 75.0,
        items: [
          const SaleItem(
            id: 'item_1',
            saleId: 'sale_custom_01',
            productId: 'p_1',
            productName: 'Paneer Butter Masala',
            categoryName: 'Mains',
            unitPrice: 200.0,
            quantity: 2.0,
            totalAmount: 400.0,
          ),
          const SaleItem(
            id: 'item_2',
            saleId: 'sale_custom_01',
            productId: 'p_2',
            productName: 'Butter Naan',
            categoryName: 'Breads',
            unitPrice: 50.0,
            quantity: 2.0,
            totalAmount: 100.0,
          ),
        ],
      );

      sampleProfile = const BusinessProfile(
        restaurantName: 'Gourmet Junction',
        tagline: 'Authentic Indian Cuisines',
        address: '12 Brigade Road, Bangalore',
        phone: '+91 98765 00000',
        taxRegistrationNumber: '29AAAAA0000A1Z5',
        currencySymbol: '₹',
        receiptFooter: 'Thank you for dining with us!',
      );

      sampleTax = const TaxSettings(
        taxName: 'GST',
        defaultTaxRate: 5.0,
        isTaxEnabled: true,
      );
    });

    test('generates valid PDF receipt bytes with default customizer settings', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final service = ReceiptGeneratorService();
      final bytes = await service.generatePdfReceipt(
        sale: sampleSale,
        profile: sampleProfile,
        taxSettings: sampleTax,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('generates valid PDF receipt bytes with minimal/toggled-off settings', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final service = ReceiptGeneratorService();

      const minimalConfig = BillCustomizerSettings(
        showBusinessName: false,
        showTagline: false,
        showAddress: false,
        showPhone: false,
        showTaxId: false,
        showInvoiceNumber: true,
        showDateTime: false,
        showCustomerDetails: false,
        showPaymentMode: false,
        showItemPrice: false, // 3-column compact mode
        showSubtotal: false,
        showGrandTotal: true,
        showCashChange: false,
        showFooter: false,
        showOrderTicketKot: false,
        cutPaper: false,
      );

      final bytes = await service.generatePdfReceipt(
        sale: sampleSale,
        profile: sampleProfile,
        taxSettings: sampleTax,
        customizerSettings: minimalConfig,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(500));
    });

    test('generates valid PDF receipt bytes with only KOT order ticket enabled', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final service = ReceiptGeneratorService();

      const kotOnlyConfig = BillCustomizerSettings(
        showBusinessName: true,
        showTagline: false,
        showAddress: false,
        showPhone: false,
        showTaxId: false,
        showInvoiceNumber: true,
        showDateTime: true,
        showCustomerDetails: true,
        showPaymentMode: true,
        showItemPrice: true,
        showSubtotal: true,
        showGrandTotal: true,
        showCashChange: true,
        showFooter: true,
        showOrderTicketKot: true,
      );

      final bytes = await service.generatePdfReceipt(
        sale: sampleSale,
        profile: sampleProfile,
        taxSettings: sampleTax,
        customizerSettings: kotOnlyConfig,
      );

      expect(bytes, isNotEmpty);
    });
  });

  group('SqliteDataSource Bill Customizer Persistence Tests', () {
    test('auto-creates bill_customizer table and saves settings without crashing', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dataSource = SqliteDataSource();
      final initialSettings = await dataSource.getBillCustomizerSettings();
      expect(initialSettings, isNotNull);

      // Save custom settings
      const customSettings = BillCustomizerSettings(
        showBusinessName: true,
        showPhone: false,
        showItemPrice: false,
        showOrderTicketKot: false,
      );
      await dataSource.saveBillCustomizerSettings(customSettings.toMap());

      final reloaded = await dataSource.getBillCustomizerSettings();
      expect(reloaded, isNotNull);
      final entity = BillCustomizerSettings.fromMap(reloaded!);
      expect(entity.showPhone, isFalse);
      expect(entity.showItemPrice, isFalse);
      expect(entity.showOrderTicketKot, isFalse);
      expect(entity.showBusinessName, isTrue);
    });
  });
}
