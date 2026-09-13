import 'dart:convert';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/held_bill.dart';
import 'product_model.dart';

class HeldBillModel extends HeldBill {
  const HeldBillModel({
    required super.id,
    required super.tableOrReference,
    super.customerId,
    super.customerName,
    required super.items,
    required super.totalAmount,
    required super.heldAt,
    super.note = '',
  });

  factory HeldBillModel.fromEntity(HeldBill heldBill) {
    return HeldBillModel(
      id: heldBill.id,
      tableOrReference: heldBill.tableOrReference,
      customerId: heldBill.customerId,
      customerName: heldBill.customerName,
      items: heldBill.items,
      totalAmount: heldBill.totalAmount,
      heldAt: heldBill.heldAt,
      note: heldBill.note,
    );
  }

  factory HeldBillModel.fromMap(Map<String, dynamic> map) {
    final itemsJson = map['items_json'] as String;
    final List<dynamic> decoded = jsonDecode(itemsJson);
    final items = decoded.map((itemMap) {
      final prodMap = itemMap['product'] as Map<String, dynamic>;
      final product = ProductModel.fromMap(prodMap);
      return CartItem(
        product: product,
        quantity: (itemMap['quantity'] as num).toDouble(),
        unitPrice: (itemMap['unit_price'] as num).toDouble(),
        discountPercent: (itemMap['discount_percent'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (itemMap['discount_amount'] as num?)?.toDouble() ?? 0.0,
        note: (itemMap['note'] as String?) ?? '',
      );
    }).toList();

    return HeldBillModel(
      id: map['id'] as String,
      tableOrReference: map['table_or_reference'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      items: items,
      totalAmount: (map['total_amount'] as num).toDouble(),
      heldAt: DateTime.parse(map['held_at'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final itemsList = items.map((item) {
      return {
        'product': ProductModel.fromEntity(item.product).toMap(),
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'discount_percent': item.discountPercent,
        'discount_amount': item.discountAmount,
        'note': item.note,
      };
    }).toList();

    return {
      'id': id,
      'table_or_reference': tableOrReference,
      'customer_id': customerId,
      'customer_name': customerName,
      'items_json': jsonEncode(itemsList),
      'total_amount': totalAmount,
      'held_at': heldAt.toIso8601String(),
      'note': note,
    };
  }
}
