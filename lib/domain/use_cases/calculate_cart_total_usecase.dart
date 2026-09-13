import '../entities/cart_item.dart';
import '../entities/tax_settings.dart';

class CartCalculationResult {
  final double subtotal;
  final double itemDiscounts;
  final double cartDiscount;
  final double totalDiscount;
  final double taxAmount;
  final double serviceCharge;
  final double roundOff;
  final double grandTotal;
  final double totalCost;

  const CartCalculationResult({
    required this.subtotal,
    required this.itemDiscounts,
    required this.cartDiscount,
    required this.totalDiscount,
    required this.taxAmount,
    required this.serviceCharge,
    required this.roundOff,
    required this.grandTotal,
    required this.totalCost,
  });
}

class CalculateCartTotalUseCase {
  CartCalculationResult execute({
    required List<CartItem> items,
    required TaxSettings taxSettings,
    double discountPercentage = 0.0,
    double discountFixed = 0.0,
  }) {
    if (items.isEmpty) {
      return const CartCalculationResult(
        subtotal: 0.0,
        itemDiscounts: 0.0,
        cartDiscount: 0.0,
        totalDiscount: 0.0,
        taxAmount: 0.0,
        serviceCharge: 0.0,
        roundOff: 0.0,
        grandTotal: 0.0,
        totalCost: 0.0,
      );
    }

    double subtotal = 0.0;
    double itemDiscounts = 0.0;
    double totalCost = 0.0;
    double calculatedTax = 0.0;

    for (final item in items) {
      final gross = item.quantity * item.unitPrice;
      subtotal += gross;
      itemDiscounts += item.effectiveDiscount;
      totalCost += item.quantity * item.product.costPrice;

      if (taxSettings.isTaxEnabled) {
        final netItem = (gross - item.effectiveDiscount).clamp(0.0, double.infinity);
        final rate = item.product.taxRate > 0 ? item.product.taxRate : taxSettings.defaultTaxRate;
        if (taxSettings.isTaxInclusive) {
          // Price already includes tax
          final taxPortion = netItem - (netItem / (1 + (rate / 100)));
          calculatedTax += taxPortion;
        } else {
          calculatedTax += netItem * (rate / 100);
        }
      }
    }

    final postItemDiscount = (subtotal - itemDiscounts).clamp(0.0, double.infinity);
    double cartDiscount = 0.0;
    if (discountPercentage > 0) {
      cartDiscount = postItemDiscount * (discountPercentage / 100);
    } else if (discountFixed > 0) {
      cartDiscount = discountFixed;
    }

    final totalDiscount = itemDiscounts + cartDiscount;
    final taxableBase = (subtotal - totalDiscount).clamp(0.0, double.infinity);

    double serviceCharge = 0.0;
    if (taxSettings.isServiceChargeEnabled && taxSettings.serviceChargeRate > 0) {
      serviceCharge = taxableBase * (taxSettings.serviceChargeRate / 100);
    }

    double rawTotal = taxableBase + serviceCharge;
    if (!taxSettings.isTaxInclusive && taxSettings.isTaxEnabled) {
      rawTotal += calculatedTax;
    }

    double roundOff = 0.0;
    double grandTotal = rawTotal;
    if (taxSettings.isRoundOffEnabled) {
      final rounded = rawTotal.roundToDouble();
      roundOff = (rounded - rawTotal);
      grandTotal = rounded;
    }

    return CartCalculationResult(
      subtotal: double.parse(subtotal.toStringAsFixed(2)),
      itemDiscounts: double.parse(itemDiscounts.toStringAsFixed(2)),
      cartDiscount: double.parse(cartDiscount.toStringAsFixed(2)),
      totalDiscount: double.parse(totalDiscount.toStringAsFixed(2)),
      taxAmount: double.parse(calculatedTax.toStringAsFixed(2)),
      serviceCharge: double.parse(serviceCharge.toStringAsFixed(2)),
      roundOff: double.parse(roundOff.toStringAsFixed(2)),
      grandTotal: double.parse(grandTotal.toStringAsFixed(2)),
      totalCost: double.parse(totalCost.toStringAsFixed(2)),
    );
  }
}
