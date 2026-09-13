import '../../domain/entities/sale.dart';
import 'sale_item_model.dart';

class SaleModel extends Sale {
  const SaleModel({
    required super.id,
    required super.invoiceNumber,
    required super.createdAt,
    super.customerId,
    super.customerName,
    super.customerPhone,
    required super.items,
    required super.subtotal,
    super.discountAmount = 0.0,
    super.taxAmount = 0.0,
    super.serviceCharge = 0.0,
    super.roundOff = 0.0,
    required super.totalAmount,
    super.costTotal = 0.0,
    required super.paymentMode,
    super.cashTendered = 0.0,
    super.changeReturned = 0.0,
    super.status = SaleStatus.completed,
    super.paymentReference,
    super.note = '',
  });

  factory SaleModel.fromEntity(Sale sale) {
    return SaleModel(
      id: sale.id,
      invoiceNumber: sale.invoiceNumber,
      createdAt: sale.createdAt,
      customerId: sale.customerId,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      items: sale.items.map((i) => SaleItemModel.fromEntity(i)).toList(),
      subtotal: sale.subtotal,
      discountAmount: sale.discountAmount,
      taxAmount: sale.taxAmount,
      serviceCharge: sale.serviceCharge,
      roundOff: sale.roundOff,
      totalAmount: sale.totalAmount,
      costTotal: sale.costTotal,
      paymentMode: sale.paymentMode,
      cashTendered: sale.cashTendered,
      changeReturned: sale.changeReturned,
      status: sale.status,
      paymentReference: sale.paymentReference,
      note: sale.note,
    );
  }

  factory SaleModel.fromMap(Map<String, dynamic> map, [List<SaleItemModel>? items]) {
    return SaleModel(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      items: items ?? [],
      subtotal: (map['subtotal'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      serviceCharge: (map['service_charge'] as num?)?.toDouble() ?? 0.0,
      roundOff: (map['round_off'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      costTotal: (map['cost_total'] as num?)?.toDouble() ?? 0.0,
      paymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == map['payment_mode'],
        orElse: () => PaymentMode.cash,
      ),
      cashTendered: (map['cash_tendered'] as num?)?.toDouble() ?? 0.0,
      changeReturned: (map['change_returned'] as num?)?.toDouble() ?? 0.0,
      status: SaleStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SaleStatus.completed,
      ),
      paymentReference: map['payment_reference'] as String?,
      note: (map['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'created_at': createdAt.toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'service_charge': serviceCharge,
      'round_off': roundOff,
      'total_amount': totalAmount,
      'cost_total': costTotal,
      'payment_mode': paymentMode.name,
      'cash_tendered': cashTendered,
      'change_returned': changeReturned,
      'status': status.name,
      'payment_reference': paymentReference,
      'note': note,
    };
  }
}
