import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundamentzz/core/services/image_service.dart';
import 'package:fundamentzz/domain/entities/category.dart';
import 'package:fundamentzz/domain/entities/product.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Product & Dish Image Model Tests', () {
    test('Product supports imagePath and colorValue serialization', () {
      final product = Product(
        id: 'p_101',
        name: 'Crispy Butter Chicken',
        categoryId: 'cat_mains',
        categoryName: 'Main Course',
        sellingPrice: 320.0,
        costPrice: 180.0,
        stockQuantity: 45.0,
        unit: 'portion',
        taxRate: 5.0,
        barcode: 'BC101',
        imagePath: '/data/user/0/com.example.fundamentzz/app_flutter/product_images/dish_sample.jpg',
        colorValue: 0xFF1E5FDE,
      );

      expect(product.imagePath, isNotNull);
      expect(product.imagePath, contains('dish_sample.jpg'));
      expect(product.colorValue, equals(0xFF1E5FDE));
      expect(product.isOutOfStock, isFalse);
      expect(product.isLowStock, isFalse);

      final updated = product.copyWith(
        sellingPrice: 350.0,
        stockQuantity: 2.0,
        lowStockThreshold: 5.0,
      );
      expect(updated.sellingPrice, equals(350.0));
      expect(updated.isLowStock, isTrue);
      expect(updated.imagePath, equals(product.imagePath));
    });

    test('Category model initializes and copies correctly', () {
      const cat = Category(
        id: 'cat_starters',
        name: 'Starters & Appetizers',
        icon: 'restaurant',
        colorValue: 0xFF1E5FDE,
      );

      expect(cat.name, equals('Starters & Appetizers'));
      expect(cat.colorValue, equals(0xFF1E5FDE));
    });
  });

  group('Image Compression Metadata Tests', () {
    test('CompressedImageResult calculates savings percentage correctly', () {
      const result = CompressedImageResult(
        filePath: '/tmp/test.jpg',
        originalSizeBytes: 2000000, // ~2MB
        compressedSizeBytes: 200000, // ~200KB
        width: 800,
        height: 600,
      );

      expect(result.savingsPercent, equals('90%'));
      expect(result.formattedOriginalSize, contains('MB'));
      expect(result.formattedCompressedSize, contains('KB'));
    });

    test('Raw image buffer resizing logic operates within max dimensions', () {
      // Create a 1200x900 synthetic test image
      final testImage = img.Image(width: 1200, height: 900);
      testImage.clear(img.ColorRgb8(255, 100, 50));
      final encodedOriginal = img.encodeJpg(testImage, quality: 100);

      // Verify original decoded size
      final decoded = img.decodeImage(encodedOriginal);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1200));
      expect(decoded.height, equals(900));

      // Simulate compression resizing
      img.Image processed = decoded;
      const maxDim = 800;
      if (processed.width > maxDim || processed.height > maxDim) {
        if (processed.width >= processed.height) {
          processed = img.copyResize(processed, width: maxDim);
        } else {
          processed = img.copyResize(processed, height: maxDim);
        }
      }

      final compressedBytes = Uint8List.fromList(img.encodeJpg(processed, quality: 80));

      expect(processed.width, equals(800));
      expect(processed.height, equals(600));
      expect(compressedBytes.lengthInBytes, lessThan(encodedOriginal.lengthInBytes));
    });
  });
}
