import '../../domain/entities/customer_ledger_entry.dart';

class CustomerLedgerEntryModel extends CustomerLedgerEntry {
  const CustomerLedgerEntryModel({
    required super.id,
    required super.customerId,
    super.saleId,
    required super.type,
    required super.amount,
    required super.balanceAfter,
    required super.timestamp,
    super.paymentMode = 'Cash',
    super.notes = '',
  });

  factory CustomerLedgerEntryModel.fromEntity(CustomerLedgerEntry entry) {
    return CustomerLedgerEntryModel(
      id: entry.id,
      customerId: entry.customerId,
      saleId: entry.saleId,
      type: entry.type,
      amount: entry.amount,
      balanceAfter: entry.balanceAfter,
      timestamp: entry.timestamp,
      paymentMode: entry.paymentMode,
      notes: entry.notes,
    );
  }

  factory CustomerLedgerEntryModel.fromMap(Map<String, dynamic> map) {
    return CustomerLedgerEntryModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      saleId: map['sale_id'] as String?,
      type: LedgerEntryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => LedgerEntryType.creditSale,
      ),
      amount: (map['amount'] as num).toDouble(),
      balanceAfter: (map['balance_after'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      paymentMode: (map['payment_mode'] as String?) ?? 'Cash',
      notes: (map['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'sale_id': saleId,
      'type': type.name,
      'amount': amount,
      'balance_after': balanceAfter,
      'timestamp': timestamp.toIso8601String(),
      'payment_mode': paymentMode,
      'notes': notes,
    };
  }
}
