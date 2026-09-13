import '../../domain/entities/stock_adjustment.dart';

class StockAdjustmentModel extends StockAdjustment {
  const StockAdjustmentModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.type,
    required super.quantityChange,
    required super.newStockQuantity,
    required super.reason,
    required super.timestamp,
    super.notes = '',
  });

  factory StockAdjustmentModel.fromEntity(StockAdjustment adjustment) {
    return StockAdjustmentModel(
      id: adjustment.id,
      productId: adjustment.productId,
      productName: adjustment.productName,
      type: adjustment.type,
      quantityChange: adjustment.quantityChange,
      newStockQuantity: adjustment.newStockQuantity,
      reason: adjustment.reason,
      timestamp: adjustment.timestamp,
      notes: adjustment.notes,
    );
  }

  factory StockAdjustmentModel.fromMap(Map<String, dynamic> map) {
    return StockAdjustmentModel(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      type: StockAdjustmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StockAdjustmentType.stockIn,
      ),
      quantityChange: (map['quantity_change'] as num).toDouble(),
      newStockQuantity: (map['new_stock_quantity'] as num).toDouble(),
      reason: (map['reason'] as String?) ?? 'Adjustment',
      timestamp: DateTime.parse(map['timestamp'] as String),
      notes: (map['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'type': type.name,
      'quantity_change': quantityChange,
      'new_stock_quantity': newStockQuantity,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }
}
