import 'sale_item.dart';

enum PaymentMode {
  cash,
  card,
  upi,
  credit, // Udhaar
  split,
}

enum SaleStatus {
  completed,
  refunded,
  cancelled,
}

class Sale {
  final String id;
  final String invoiceNumber;
  final DateTime createdAt;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final List<SaleItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double serviceCharge;
  final double roundOff;
  final double totalAmount;
  final double costTotal;
  final PaymentMode paymentMode;
  final double cashTendered;
  final double changeReturned;
  final SaleStatus status;
  final String? paymentReference;
  final String note;

  const Sale({
    required this.id,
    required this.invoiceNumber,
    required this.createdAt,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.serviceCharge = 0.0,
    this.roundOff = 0.0,
    required this.totalAmount,
    this.costTotal = 0.0,
    required this.paymentMode,
    this.cashTendered = 0.0,
    this.changeReturned = 0.0,
    this.status = SaleStatus.completed,
    this.paymentReference,
    this.note = '',
  });

  double get netProfit => totalAmount - taxAmount - costTotal;

  int get totalItemCount => items.fold<int>(0, (sum, item) => sum + item.quantity.toInt());

  Sale copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? createdAt,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<SaleItem>? items,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? serviceCharge,
    double? roundOff,
    double? totalAmount,
    double? costTotal,
    PaymentMode? paymentMode,
    double? cashTendered,
    double? changeReturned,
    SaleStatus? status,
    String? paymentReference,
    String? note,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      roundOff: roundOff ?? this.roundOff,
      totalAmount: totalAmount ?? this.totalAmount,
      costTotal: costTotal ?? this.costTotal,
      paymentMode: paymentMode ?? this.paymentMode,
      cashTendered: cashTendered ?? this.cashTendered,
      changeReturned: changeReturned ?? this.changeReturned,
      status: status ?? this.status,
      paymentReference: paymentReference ?? this.paymentReference,
      note: note ?? this.note,
    );
  }
}
