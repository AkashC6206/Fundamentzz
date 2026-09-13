import '../../domain/entities/sale_item.dart';

class SaleItemModel extends SaleItem {
  const SaleItemModel({
    required super.id,
    required super.saleId,
    required super.productId,
    required super.productName,
    required super.categoryName,
    required super.quantity,
    required super.unitPrice,
    super.costPrice = 0.0,
    super.discountAmount = 0.0,
    super.taxAmount = 0.0,
    required super.totalAmount,
    super.note = '',
  });

  factory SaleItemModel.fromEntity(SaleItem item) {
    return SaleItemModel(
      id: item.id,
      saleId: item.saleId,
      productId: item.productId,
      productName: item.productName,
      categoryName: item.categoryName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      costPrice: item.costPrice,
      discountAmount: item.discountAmount,
      taxAmount: item.taxAmount,
      totalAmount: item.totalAmount,
      note: item.note,
    );
  }

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] as String,
      saleId: map['sale_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      categoryName: (map['category_name'] as String?) ?? '',
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      note: (map['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'category_name': categoryName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'note': note,
    };
  }
}
