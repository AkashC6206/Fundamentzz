import 'product.dart';

class CartItem {
  final Product product;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final String note;

  const CartItem({
    required this.product,
    this.quantity = 1.0,
    required this.unitPrice,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.note = '',
  });

  double get grossTotal => quantity * unitPrice;

  double get effectiveDiscount {
    if (discountPercent > 0) {
      return grossTotal * (discountPercent / 100);
    }
    return discountAmount;
  }

  double get netTotal => (grossTotal - effectiveDiscount).clamp(0.0, double.infinity);

  double get taxAmount {
    // Computed based on product tax rate
    return netTotal * (product.taxRate / 100);
  }

  double get totalWithTax => netTotal + taxAmount;

  CartItem copyWith({
    Product? product,
    double? quantity,
    double? unitPrice,
    double? discountPercent,
    double? discountAmount,
    String? note,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      note: note ?? this.note,
    );
  }
}
