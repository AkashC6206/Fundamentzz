class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final String categoryName;
  final double quantity;
  final double unitPrice;
  final double costPrice;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String note;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.quantity,
    required this.unitPrice,
    this.costPrice = 0.0,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    required this.totalAmount,
    this.note = '',
  });

  double get profit => totalAmount - (costPrice * quantity);

  SaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    String? categoryName,
    double? quantity,
    double? unitPrice,
    double? costPrice,
    double? discountAmount,
    double? taxAmount,
    double? totalAmount,
    String? note,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
    );
  }
}
