enum LedgerEntryType {
  creditSale, // Customer bought on credit (Debit to Customer balance / Udhaar increase)
  paymentReceived, // Customer paid money (Credit to Customer balance / Udhaar reduction)
}

class CustomerLedgerEntry {
  final String id;
  final String customerId;
  final String? saleId;
  final LedgerEntryType type;
  final double amount;
  final double balanceAfter;
  final DateTime timestamp;
  final String paymentMode; // 'Cash', 'UPI', 'Bank Transfer', etc.
  final String notes;

  const CustomerLedgerEntry({
    required this.id,
    required this.customerId,
    this.saleId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.timestamp,
    this.paymentMode = 'Cash',
    this.notes = '',
  });

  CustomerLedgerEntry copyWith({
    String? id,
    String? customerId,
    String? saleId,
    LedgerEntryType? type,
    double? amount,
    double? balanceAfter,
    DateTime? timestamp,
    String? paymentMode,
    String? notes,
  }) {
    return CustomerLedgerEntry(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      saleId: saleId ?? this.saleId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      timestamp: timestamp ?? this.timestamp,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
    );
  }
}
