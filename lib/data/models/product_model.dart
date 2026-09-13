import 'package:flutter/foundation.dart';
import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.categoryId,
    required super.categoryName,
    required super.sellingPrice,
    super.costPrice = 0.0,
    super.stockQuantity = 0.0,
    super.lowStockThreshold = 5.0,
    super.unit = 'portion',
    super.barcode = '',
    super.imagePath,
    super.colorValue = 0xFF1E5FDE,
    super.taxRate = 5.0,
    super.isAvailable = true,
  });

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      sellingPrice: product.sellingPrice,
      costPrice: product.costPrice,
      stockQuantity: product.stockQuantity,
      lowStockThreshold: product.lowStockThreshold,
      unit: product.unit,
      barcode: product.barcode,
      imagePath: product.imagePath,
      colorValue: product.colorValue,
      taxRate: product.taxRate,
      isAvailable: product.isAvailable,
    );
  }

  static double _parseDouble(dynamic val, {double defaultValue = 0.0}) {
    if (val == null) return defaultValue;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  static int _parseInt(dynamic val, {int defaultValue = 0}) {
    if (val == null) return defaultValue;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  static bool _parseBool(dynamic val, {bool defaultValue = true}) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final s = val.trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return defaultValue;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    debugPrint('[MODEL] Converting ProductModel from map: id=${map['id']}, name=${map['name']}');
    return ProductModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      categoryName: map['category_name']?.toString() ?? 'General',
      sellingPrice: _parseDouble(map['selling_price']),
      costPrice: _parseDouble(map['cost_price']),
      stockQuantity: _parseDouble(map['stock_quantity']),
      lowStockThreshold: _parseDouble(map['low_stock_threshold'], defaultValue: 5.0),
      unit: map['unit']?.toString() ?? 'portion',
      barcode: map['barcode']?.toString() ?? '',
      imagePath: map['image_path'] as String?,
      colorValue: _parseInt(map['color_value'], defaultValue: 0xFF1E5FDE),
      taxRate: _parseDouble(map['tax_rate'], defaultValue: 5.0),
      isAvailable: _parseBool(map['is_available'], defaultValue: true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'category_name': categoryName,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'unit': unit,
      'barcode': barcode,
      'image_path': imagePath,
      'color_value': colorValue,
      'tax_rate': taxRate,
      'is_available': isAvailable ? 1 : 0,
    };
  }
}
