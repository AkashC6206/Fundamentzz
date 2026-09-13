import 'package:flutter_test/flutter_test.dart';
import 'package:fundamentzz/core/utils/currency_formatter.dart';
import 'package:fundamentzz/core/utils/date_formatter.dart';
import 'package:fundamentzz/core/utils/result.dart';
import 'package:fundamentzz/domain/entities/cart_item.dart';
import 'package:fundamentzz/domain/entities/product.dart';
import 'package:fundamentzz/domain/entities/tax_settings.dart';
import 'package:fundamentzz/domain/use_cases/calculate_cart_total_usecase.dart';

void main() {
  group('CalculateCartTotalUseCase Tests', () {
    late CalculateCartTotalUseCase useCase;

    setUp(() {
      useCase = CalculateCartTotalUseCase();
    });

    final testProduct1 = Product(
      id: 'p1',
      name: 'Paneer Tikka',
      categoryId: 'c1',
      categoryName: 'Starters',
      sellingPrice: 200.0,
      costPrice: 100.0,
      stockQuantity: 20.0,
      unit: 'portion',
      taxRate: 5.0,
    );

    final testProduct2 = Product(
      id: 'p2',
      name: 'Mango Lassi',
      categoryId: 'c2',
      categoryName: 'Beverages',
      sellingPrice: 100.0,
      costPrice: 40.0,
      stockQuantity: 50.0,
      unit: 'glass',
      taxRate: 5.0,
    );

    test('should calculate subtotal and tax correctly with default settings', () {
      final items = [
        CartItem(product: testProduct1, quantity: 2, unitPrice: 200.0), // 400
        CartItem(product: testProduct2, quantity: 1, unitPrice: 100.0), // 100
      ];

      const taxSettings = TaxSettings(
        isTaxEnabled: true,
        isTaxInclusive: false,
        taxName: 'GST',
        defaultTaxRate: 5.0,
        isServiceChargeEnabled: false,
        serviceChargeRate: 0.0,
        isRoundOffEnabled: true,
      );

      final totals = useCase.execute(
        items: items,
        taxSettings: taxSettings,
      );

      expect(totals.subtotal, equals(500.0));
      expect(totals.taxAmount, equals(25.0)); // 5% of 500
      expect(totals.grandTotal, equals(525.0));
    });

    test('should apply bill discount and round-off correctly', () {
      final items = [
        CartItem(product: testProduct1, quantity: 1, unitPrice: 200.0),
      ];

      const taxSettings = TaxSettings(
        isTaxEnabled: true,
        isTaxInclusive: false,
        taxName: 'GST',
        defaultTaxRate: 5.0,
        isServiceChargeEnabled: false,
        serviceChargeRate: 0.0,
        isRoundOffEnabled: true,
      );

      final totals = useCase.execute(
        items: items,
        taxSettings: taxSettings,
        discountFixed: 50.0,
      );

      // Subtotal = 200, Discount = 50, Net taxable = 150, Tax 5% = 10 (on gross item tax), Total with roundoff
      expect(totals.subtotal, equals(200.0));
      expect(totals.totalDiscount, equals(50.0));
      expect(totals.taxAmount, equals(10.0));
      expect(totals.grandTotal, equals(160.0));
    });
  });

  group('Utility Formatting Tests', () {
    test('CurrencyFormatter formats INR correctly', () {
      expect(CurrencyFormatter.format(1250), contains('1,250'));
      expect(CurrencyFormatter.format(0), contains('0'));
    });

    test('DateFormatter formats timestamps without crashing', () {
      final dt = DateTime(2026, 8, 19, 14, 30);
      expect(DateFormatter.formatDate(dt), isNotEmpty);
      expect(DateFormatter.formatDateTime(dt), isNotEmpty);
      expect(DateFormatter.formatTime(dt), isNotEmpty);
    });

    test('Result class handles success and error monads', () {
      final success = Result.success('data');
      expect(success.isSuccess, isTrue);
      expect(success.data, equals('data'));

      final failure = Result<String>.error(null);
      expect(failure.isSuccess, isFalse);
    });
  });
}
