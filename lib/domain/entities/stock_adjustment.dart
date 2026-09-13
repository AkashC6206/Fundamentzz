enum StockAdjustmentType {
  stockIn,
  stockOut,
  setExact,
}

class StockAdjustment {
  final String id;
  final String productId;
  final String productName;
  final StockAdjustmentType type;
  final double quantityChange;
  final double newStockQuantity;
  final String reason; // 'Purchase', 'Damaged', 'Returned', 'Audit Discrepancy', 'Free Sample'
  final DateTime timestamp;
  final String notes;

  const StockAdjustment({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantityChange,
    required this.newStockQuantity,
    required this.reason,
    required this.timestamp,
    this.notes = '',
  });

  StockAdjustment copyWith({
    String? id,
    String? productId,
    String? productName,
    StockAdjustmentType? type,
    double? quantityChange,
    double? newStockQuantity,
    String? reason,
    DateTime? timestamp,
    String? notes,
  }) {
    return StockAdjustment(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantityChange: quantityChange ?? this.quantityChange,
      newStockQuantity: newStockQuantity ?? this.newStockQuantity,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
}
