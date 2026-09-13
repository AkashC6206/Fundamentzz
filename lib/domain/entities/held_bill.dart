import 'cart_item.dart';

class HeldBill {
  final String id;
  final String tableOrReference;
  final String? customerId;
  final String? customerName;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime heldAt;
  final String note;

  const HeldBill({
    required this.id,
    required this.tableOrReference,
    this.customerId,
    this.customerName,
    required this.items,
    required this.totalAmount,
    required this.heldAt,
    this.note = '',
  });

  HeldBill copyWith({
    String? id,
    String? tableOrReference,
    String? customerId,
    String? customerName,
    List<CartItem>? items,
    double? totalAmount,
    DateTime? heldAt,
    String? note,
  }) {
    return HeldBill(
      id: id ?? this.id,
      tableOrReference: tableOrReference ?? this.tableOrReference,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      heldAt: heldAt ?? this.heldAt,
      note: note ?? this.note,
    );
  }
}
