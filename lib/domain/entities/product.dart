class Product {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double sellingPrice;
  final double costPrice;
  final double stockQuantity;
  final double lowStockThreshold;
  final String unit; // 'pcs', 'kg', 'plate', 'glass', 'portion'
  final String barcode;
  final String? imagePath;
  final int colorValue;
  final double taxRate; // e.g. 5.0 for 5% GST
  final bool isAvailable;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.sellingPrice,
    this.costPrice = 0.0,
    this.stockQuantity = 0.0,
    this.lowStockThreshold = 5.0,
    this.unit = 'portion',
    this.barcode = '',
    this.imagePath,
    this.colorValue = 0xFF1E5FDE,
    this.taxRate = 5.0,
    this.isAvailable = true,
  });

  bool get isLowStock => stockQuantity <= lowStockThreshold && stockQuantity > 0;
  bool get isOutOfStock => stockQuantity <= 0;

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    double? sellingPrice,
    double? costPrice,
    double? stockQuantity,
    double? lowStockThreshold,
    String? unit,
    String? barcode,
    String? imagePath,
    int? colorValue,
    double? taxRate,
    bool? isAvailable,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
      colorValue: colorValue ?? this.colorValue,
      taxRate: taxRate ?? this.taxRate,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
