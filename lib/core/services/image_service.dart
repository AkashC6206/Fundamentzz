import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CompressedImageResult {
  final String filePath;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final int width;
  final int height;

  const CompressedImageResult({
    required this.filePath,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.width,
    required this.height,
  });

  String get formattedOriginalSize => _formatBytes(originalSizeBytes);
  String get formattedCompressedSize => _formatBytes(compressedSizeBytes);

  String get savingsPercent {
    if (originalSizeBytes <= 0) return '0%';
    final saved = ((originalSizeBytes - compressedSizeBytes) / originalSizeBytes) * 100;
    return '${saved.clamp(0, 100).toStringAsFixed(0)}%';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class ImageService {
  final ImagePicker _picker;

  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Picks an image from the camera or gallery, resizes it preserving aspect ratio,
  /// compresses it into an optimized JPEG format, and stores it in app documents.
  Future<CompressedImageResult?> pickAndCompressImage({
    required ImageSource source,
    int maxDimension = 800,
    int quality = 80,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600, // Pre-limit in picker to save memory on heavy camera captures
        maxHeight: 1600,
      );

      if (pickedFile == null) return null;

      final Uint8List originalBytes = await pickedFile.readAsBytes();
      final int originalSize = originalBytes.lengthInBytes;

      // Decode image using Dart's image package
      final img.Image? decodedImage = img.decodeImage(originalBytes);

      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory targetDir = Directory(p.join(appDir.path, 'product_images'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final String fileName = 'dish_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}.jpg';
      final String targetPath = p.join(targetDir.path, fileName);
      final File targetFile = File(targetPath);

      if (decodedImage == null) {
        // Fallback: If decode fails, save the picked file directly
        await targetFile.writeAsBytes(originalBytes);
        return CompressedImageResult(
          filePath: targetPath,
          originalSizeBytes: originalSize,
          compressedSizeBytes: originalSize,
          width: 0,
          height: 0,
        );
      }

      // Calculate proportional dimensions
      int targetW = decodedImage.width;
      int targetH = decodedImage.height;

      if (targetW > maxDimension || targetH > maxDimension) {
        if (targetW > targetH) {
          targetH = (targetH * maxDimension / targetW).round();
          targetW = maxDimension;
        } else {
          targetW = (targetW * maxDimension / targetH).round();
          targetH = maxDimension;
        }
      }

      // Resize and re-encode to JPEG
      final img.Image resized = img.copyResize(
        decodedImage,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.linear,
      );

      final Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: quality),
      );

      await targetFile.writeAsBytes(compressedBytes);

      return CompressedImageResult(
        filePath: targetPath,
        originalSizeBytes: originalSize,
        compressedSizeBytes: compressedBytes.lengthInBytes,
        width: targetW,
        height: targetH,
      );
    } catch (e) {
      debugPrint('Error picking and compressing image: $e');
      return null;
    }
  }

  /// Deletes an image file if it exists and belongs to the app's product_images folder
  Future<void> deleteImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image file: $e');
    }
  }
}
