import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundamentzz/core/services/bluetooth_printer_service.dart';
import 'package:fundamentzz/domain/entities/bill_customizer_settings.dart';
import 'package:fundamentzz/domain/entities/business_profile.dart';
import 'package:fundamentzz/domain/entities/product.dart';
import 'package:fundamentzz/domain/entities/sale.dart';
import 'package:fundamentzz/domain/entities/tax_settings.dart';
import 'package:fundamentzz/domain/use_cases/calculate_cart_total_usecase.dart';
import 'package:fundamentzz/presentation/providers/billing_provider.dart';
import 'package:fundamentzz/presentation/providers/settings_provider.dart';
import 'package:fundamentzz/presentation/views/billing/new_sale_view.dart';
import 'package:fundamentzz/presentation/views/billing/payment_modal.dart';
import 'package:fundamentzz/presentation/views/billing/pos_quick_quantity_dialog.dart';
import 'package:fundamentzz/presentation/views/billing/receipt_view.dart';
import 'package:fundamentzz/presentation/widgets/custom_button.dart';
import 'package:fundamentzz/presentation/widgets/custom_card.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('CustomButton renders text and triggers callback', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'NEW SALE',
            icon: Icons.flash_on,
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('NEW SALE'), findsOneWidget);
    expect(find.byIcon(Icons.flash_on), findsOneWidget);

    await tester.tap(find.byType(CustomButton));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('CustomCard renders child correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomCard(
            child: Text('Card Content'),
          ),
        ),
      ),
    );

    expect(find.text('Card Content'), findsOneWidget);
  });

  testWidgets('PosQuickQuantityDialog renders native input, presets, and updates digits', (WidgetTester tester) async {
    const sampleProduct = Product(
      id: 'p_test_1',
      name: 'Paneer Butter Masala',
      categoryId: 'cat_1',
      categoryName: 'Mains',
      sellingPrice: 250.0,
    );

    double selectedQty = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                PosQuickQuantityDialog.show(
                  context,
                  product: sampleProduct,
                  currentQuantity: 3,
                  onQuantitySelected: (q) => selectedQty = q,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify product name and initial quantity
    expect(find.text('Paneer Butter Masala'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Tap preset +10
    expect(find.text('+10'), findsOneWidget);
    await tester.tap(find.text('+10'));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);

    // Enter direct quantity using device keyboard input into TextField
    await tester.enterText(find.byType(TextField), '25');
    await tester.pumpAndSettle();
    expect(find.text('25'), findsOneWidget);

    // Tap confirm button
    await tester.ensureVisible(find.text('Set Quantity'));
    await tester.tap(find.text('Set Quantity'));
    await tester.pumpAndSettle();

    expect(selectedQty, equals(25.0));
  });

  testWidgets('QuickOrderItemTile renders without layout overflow or infinite width errors', (WidgetTester tester) async {
    const sampleProduct = Product(
      id: 'p_test_2',
      name: 'Garlic Naan',
      categoryId: 'cat_breads',
      categoryName: 'Breads',
      sellingPrice: 60.0,
    );

    int addCount = 0;
    int decrementCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickOrderItemTile(
            product: sampleProduct,
            quantityInCart: 4,
            onAddToCart: () => addCount++,
            onDecrement: () => decrementCount++,
            onSetQuantity: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Garlic Naan'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Line Total: ₹ 240.00'), findsOneWidget);

    // Tap increment (+)
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pump();
    expect(addCount, equals(1));

    // Tap decrement (−)
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(decrementCount, equals(1));

    // Tapping anywhere on card MUST also trigger onAddToCart (+1)
    await tester.tap(find.text('Garlic Naan'));
    await tester.pump();
    expect(addCount, equals(2));
  });

  testWidgets('QuickOrderItemTile in GridView with mainAxisExtent renders snugly without overflow', (WidgetTester tester) async {
    const sampleProduct = Product(
      id: 'p_test_3',
      name: 'Butter Chicken',
      categoryId: 'cat_gravy',
      categoryName: 'gravy',
      sellingPrice: 350.0,
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 212,
            ),
            itemCount: 2,
            itemBuilder: (context, index) => QuickOrderItemTile(
              product: sampleProduct,
              quantityInCart: 2,
              onAddToCart: () {},
              onDecrement: () {},
              onSetQuantity: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Butter Chicken'), findsNWidgets(2));
    expect(find.text('Line Total: ₹ 700.00'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReceiptView has leading back button and pop navigates back to calling page', (WidgetTester tester) async {
    final fakeBilling = FakeBillingProvider();
    final fakeSettings = FakeSettingsProvider();
    final sale = Sale(
      id: 's1',
      invoiceNumber: 'INV-1001',
      createdAt: DateTime(2026, 9, 12, 22, 0),
      items: const [],
      subtotal: 100,
      discountAmount: 0,
      taxAmount: 0,
      serviceCharge: 0,
      roundOff: 0,
      totalAmount: 100,
      costTotal: 50,
      paymentMode: PaymentMode.cash,
      status: SaleStatus.completed,
    );

    bool popped = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BillingProvider>.value(value: fakeBilling),
          ChangeNotifierProvider<SettingsProvider>.value(value: fakeSettings),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReceiptView(sale: sale)),
                );
                popped = true;
              },
              child: const Text('Go to Receipt'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go to Receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Invoice & Receipt'), findsOneWidget);
    expect(find.byTooltip('Back to POS Billing'), findsOneWidget);

    // Tap leading back button
    await tester.tap(find.byTooltip('Back to POS Billing'));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(find.text('Go to Receipt'), findsOneWidget);
  });

  testWidgets('PaymentModal renders Select Payment Method header with Cash and UPI options only', (WidgetTester tester) async {
    final fakeBilling = FakeBillingProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<BillingProvider>.value(
        value: fakeBilling,
        child: const MaterialApp(
          home: Scaffold(
            body: PaymentModal(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Select Payment Method'), findsOneWidget);

    // Verify Cash and UPI tabs are present
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);

    // Verify other modes like Card or Udhaar are NOT present
    expect(find.text('Card'), findsNothing);
    expect(find.text('Udhaar'), findsNothing);
    expect(find.text('Credit'), findsNothing);

    // Default is Cash: verify Cash Tendered and Denomination Chips
    expect(find.text('Cash Tendered'), findsOneWidget);
    expect(find.text('Exact'), findsOneWidget);
    expect(find.text('+ ₹100'), findsOneWidget);
    expect(find.text('Change to Return:'), findsOneWidget);
    expect(find.text('CONFIRM CASH & PRINT RECEIPT'), findsOneWidget);

    // Switch to UPI
    await tester.tap(find.text('UPI'));
    await tester.pumpAndSettle();

    // Verify UPI details
    expect(find.byIcon(Icons.qr_code_2), findsWidgets);
    expect(find.text('Scan using GPay, PhonePe, Paytm or any UPI App'), findsOneWidget);
    expect(find.text('fundamentzz@okhdfcbank'), findsOneWidget);
    expect(find.text('UPI Ref / UTR (Optional)'), findsOneWidget);
    expect(find.text('CONFIRM UPI & PRINT RECEIPT'), findsOneWidget);

    // Cash-specific elements should now be hidden
    expect(find.text('Cash Tendered'), findsNothing);
    expect(find.text('Change to Return:'), findsNothing);

    // Switch back to Cash
    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();

    expect(find.text('Cash Tendered'), findsOneWidget);
    expect(find.text('CONFIRM CASH & PRINT RECEIPT'), findsOneWidget);
  });
}

class FakeBillingProvider extends ChangeNotifier implements BillingProvider {
  @override
  BusinessProfile get businessProfile => const BusinessProfile(restaurantName: 'Test Bistro');

  @override
  CartCalculationResult get cartTotals => const CartCalculationResult(
    subtotal: 500,
    itemDiscounts: 0,
    cartDiscount: 0,
    totalDiscount: 0,
    taxAmount: 0,
    serviceCharge: 0,
    roundOff: 0,
    grandTotal: 500,
    totalCost: 200,
  );

  @override
  TaxSettings get taxSettings => const TaxSettings();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get autoPrintOnSale => false;

  @override
  BluetoothPrinterInfo? get selectedPrinter => null;

  @override
  BillCustomizerSettings get billCustomizerSettings => const BillCustomizerSettings();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

