import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/datasources/sqlite_datasource.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../errors/failures.dart';
import '../utils/result.dart';

class MenuExportResult {
  final String zipFilePath;
  final int categoriesCount;
  final int productsCount;
  final int imagesCount;
  final int totalBytes;

  const MenuExportResult({
    required this.zipFilePath,
    required this.categoriesCount,
    required this.productsCount,
    required this.imagesCount,
    required this.totalBytes,
  });
}

class MenuInspectionResult {
  final Archive archive;
  final int categoriesCount;
  final int productsCount;
  final int imagesCount;
  final int currentDbProductsCount;
  final int currentDbCategoriesCount;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> products;

  const MenuInspectionResult({
    required this.archive,
    required this.categoriesCount,
    required this.productsCount,
    required this.imagesCount,
    required this.currentDbProductsCount,
    required this.currentDbCategoriesCount,
    required this.categories,
    required this.products,
  });

  bool get dbHasExistingData => currentDbProductsCount > 0 || currentDbCategoriesCount > 0;
}

class MenuImportSummary {
  final int categoriesImported;
  final int productsImported;
  final int imagesRestored;
  final int missingImagesCount;
  final bool replacedExisting;

  const MenuImportSummary({
    required this.categoriesImported,
    required this.productsImported,
    required this.imagesRestored,
    required this.missingImagesCount,
    required this.replacedExisting,
  });
}

class MenuTransferService {
  final SqliteDataSource _dataSource;

  MenuTransferService({SqliteDataSource? dataSource})
      : _dataSource = dataSource ?? SqliteDataSource();

  Future<Directory> _getProductImagesDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory targetDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  /// Exports categories, products, and associated dish images into an unencrypted ZIP archive
  Future<Result<MenuExportResult>> exportMenuToZip() async {
    try {
      final db = await _dataSource.database;

      // 1. Fetch current categories and products from SQLite
      final List<Map<String, dynamic>> catMaps = await db.query('categories', orderBy: 'name ASC');
      final List<Map<String, dynamic>> prodMaps = await db.query('products', orderBy: 'name ASC');

      if (catMaps.isEmpty && prodMaps.isEmpty) {
        return const Result.error(NotFoundFailure('No menu items or categories found to export.'));
      }

      final archive = Archive();
      int imagesExported = 0;
      final List<Map<String, dynamic>> exportedProducts = [];

      // 2. Add dish images to archive inside images/ folder
      for (final prod in prodMaps) {
        final mutableProd = Map<String, dynamic>.from(prod);
        final imagePath = prod['image_path'] as String?;

        if (imagePath != null && imagePath.trim().isNotEmpty) {
          final imgFile = File(imagePath);
          if (await imgFile.exists()) {
            try {
              final rawBytes = await imgFile.readAsBytes();
              final rawName = p.basename(imagePath);
              final zipEntryName = 'images/$rawName';

              archive.addFile(ArchiveFile(zipEntryName, rawBytes.length, rawBytes));
              mutableProd['image_filename'] = rawName;
              imagesExported++;
            } catch (e) {
              debugPrint('[MENU EXPORT] Error reading image file: $imagePath: $e');
              mutableProd['image_filename'] = null;
            }
          } else {
            mutableProd['image_filename'] = null;
          }
        } else {
          mutableProd['image_filename'] = null;
        }

        // Do not leak local device absolute path in exported json
        mutableProd.remove('image_path');
        exportedProducts.add(mutableProd);
      }

      // 3. Package menu.json at the root of the ZIP
      final menuJsonMap = {
        'format': 'fundamentzz_menu_archive',
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'categories_count': catMaps.length,
        'products_count': exportedProducts.length,
        'images_count': imagesExported,
        'categories': catMaps,
        'products': exportedProducts,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(menuJsonMap);
      final jsonBytes = utf8.encode(jsonString);
      archive.addFile(ArchiveFile('menu.json', jsonBytes.length, jsonBytes));

      // 4. Encode ZIP archive
      final zipEncoder = ZipEncoder();
      final encodedZipBytes = zipEncoder.encode(archive);

      if (encodedZipBytes.isEmpty) {
        return const Result.error(BackupRestoreFailure('Failed to generate ZIP archive.'));
      }

      // 5. Save ZIP to temporary storage and invoke share sheet
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final zipFilePath = p.join(tempDir.path, 'fundamentzz_menu_$timestamp.zip');
      final zipFile = File(zipFilePath);
      await zipFile.writeAsBytes(encodedZipBytes);

      final exportResult = MenuExportResult(
        zipFilePath: zipFilePath,
        categoriesCount: catMaps.length,
        productsCount: prodMaps.length,
        imagesCount: imagesExported,
        totalBytes: encodedZipBytes.length,
      );

      // Invoke Android Share/Save Sheet
      try {
        final xFile = XFile(zipFilePath);
        await Share.shareXFiles(
          [xFile],
          text: 'Fundamentzz Menu Export - $timestamp (${prodMaps.length} items, $imagesExported images)',
        );
      } catch (e) {
        debugPrint('[MENU EXPORT] Share sheet note: $e');
      }

      return Result.success(exportResult);
    } catch (e, stack) {
      debugPrint('[MENU EXPORT] Error: $e\n$stack');
      return Result.error(BackupRestoreFailure('Failed to export menu: ${e.toString()}'));
    }
  }

  /// Prompts user to pick a ZIP file, inspects its menu.json and images contents,
  /// and returns an inspection summary before proceeding with confirmation.
  Future<Result<MenuInspectionResult?>> pickAndInspectMenuZip() async {
    try {
      final List<PlatformFile> pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (pickedFiles.isEmpty) {
        // User cancelled picker
        return const Result.success(null);
      }

      final file = pickedFiles.first;
      final Uint8List fileBytes = await file.readAsBytes();

      if (fileBytes.isEmpty) {
        return const Result.error(BackupRestoreFailure('Unable to read selected file contents.'));
      }

      // Decode ZIP archive
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(fileBytes);
      } catch (e) {
        return const Result.error(
          BackupRestoreFailure('The selected file is not a valid or readable ZIP archive.'),
        );
      }

      // Check for menu.json inside the ZIP
      ArchiveFile? menuJsonFile;
      for (final f in archive.files) {
        if (f.isFile && (f.name == 'menu.json' || f.name.endsWith('/menu.json'))) {
          menuJsonFile = f;
          break;
        }
      }

      if (menuJsonFile == null) {
        return const Result.error(
          NotFoundFailure('Invalid menu backup: "menu.json" was not found inside the ZIP archive.'),
        );
      }

      // Parse JSON
      final dynamic rawContent = menuJsonFile.content;
      final Uint8List jsonBytes = rawContent is Uint8List
          ? rawContent
          : Uint8List.fromList(rawContent as List<int>);
      final String jsonStr = utf8.decode(jsonBytes);

      Map<String, dynamic> jsonMap;
      try {
        jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        return const Result.error(
          BackupRestoreFailure('Corrupted menu.json: Could not parse JSON content.'),
        );
      }

      final categoriesRaw = jsonMap['categories'];
      final productsRaw = jsonMap['products'];

      if (categoriesRaw is! List || productsRaw is! List) {
        return const Result.error(
          BackupRestoreFailure('Invalid menu.json format: missing "categories" or "products" list.'),
        );
      }

      final categories = categoriesRaw.whereType<Map<String, dynamic>>().toList();
      final products = productsRaw.whereType<Map<String, dynamic>>().toList();

      int imagesCount = 0;
      for (final f in archive.files) {
        if (f.isFile && f.name.startsWith('images/') && f.name.length > 7) {
          imagesCount++;
        }
      }

      // Check existing SQLite DB counts
      final db = await _dataSource.database;
      final catCountRes = await db.rawQuery('SELECT COUNT(*) as c FROM categories');
      final prodCountRes = await db.rawQuery('SELECT COUNT(*) as c FROM products');
      final curCatCount = (catCountRes.firstOrNull?['c'] as num?)?.toInt() ?? 0;
      final curProdCount = (prodCountRes.firstOrNull?['c'] as num?)?.toInt() ?? 0;

      return Result.success(MenuInspectionResult(
        archive: archive,
        categoriesCount: categories.length,
        productsCount: products.length,
        imagesCount: imagesCount,
        currentDbCategoriesCount: curCatCount,
        currentDbProductsCount: curProdCount,
        categories: categories,
        products: products,
      ));
    } catch (e, stack) {
      debugPrint('[MENU IMPORT] Inspect error: $e\n$stack');
      return Result.error(BackupRestoreFailure('Error inspecting ZIP file: ${e.toString()}'));
    }
  }

  /// Restores categories, products, and associated dish images into SQLite and local storage
  Future<Result<MenuImportSummary>> applyMenuImport({
    required MenuInspectionResult inspection,
    required bool replaceExisting,
  }) async {
    try {
      final db = await _dataSource.database;
      final productImagesDir = await _getProductImagesDirectory();

      // 1. Unpack images from ZIP archive into app's product_images folder
      final Map<String, String> restoredImageMap = {}; // original filename -> local absolute path
      int imagesRestored = 0;

      for (final f in inspection.archive.files) {
        if (f.isFile && (f.name.startsWith('images/') || f.name.contains('/images/'))) {
          final filename = p.basename(f.name);
          if (filename.isEmpty) continue;

          try {
            final dynamic content = f.content;
            final Uint8List bytes = content is Uint8List
                ? content
                : Uint8List.fromList(content as List<int>);

            final targetFile = File(p.join(productImagesDir.path, filename));
            await targetFile.writeAsBytes(bytes);
            restoredImageMap[filename] = targetFile.path;
            imagesRestored++;
          } catch (e) {
            debugPrint('[MENU IMPORT] Warning: failed to write image $filename: $e');
          }
        }
      }

      // 2. Perform SQLite transaction to import categories and products
      int missingImagesCount = 0;

      await db.transaction((txn) async {
        if (replaceExisting) {
          // Clear current products and categories if replacing
          await txn.delete('products');
          await txn.delete('categories');
        }

        // Insert / Merge Categories
        for (final catMap in inspection.categories) {
          final id = catMap['id']?.toString() ?? '';
          final name = catMap['name']?.toString() ?? '';
          if (id.isEmpty || name.isEmpty) continue;

          final categoryModel = CategoryModel(
            id: id,
            name: name,
            icon: (catMap['icon'] as String?) ?? 'restaurant',
            colorValue: (catMap['color_value'] as num?)?.toInt() ?? 0xFF1E5FDE,
          );

          await txn.insert(
            'categories',
            categoryModel.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Insert / Merge Products
        for (final prodMap in inspection.products) {
          final id = prodMap['id']?.toString() ?? '';
          final name = prodMap['name']?.toString() ?? '';
          if (id.isEmpty || name.isEmpty) continue;

          // Reconcile image path
          final imageFilename = prodMap['image_filename'] as String?;
          String? restoredPath;

          if (imageFilename != null && imageFilename.isNotEmpty) {
            if (restoredImageMap.containsKey(imageFilename)) {
              restoredPath = restoredImageMap[imageFilename];
            } else {
              // Check if image file already exists locally in product_images
              final existingImg = File(p.join(productImagesDir.path, imageFilename));
              if (existingImg.existsSync()) {
                restoredPath = existingImg.path;
              } else {
                // Image file missing in archive, handle gracefully without crashing
                missingImagesCount++;
                restoredPath = null;
              }
            }
          }

          final mutableMap = Map<String, dynamic>.from(prodMap);
          mutableMap['image_path'] = restoredPath;
          mutableMap.remove('image_filename');

          final productModel = ProductModel.fromMap(mutableMap);

          await txn.insert(
            'products',
            productModel.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return Result.success(MenuImportSummary(
        categoriesImported: inspection.categories.length,
        productsImported: inspection.products.length,
        imagesRestored: imagesRestored,
        missingImagesCount: missingImagesCount,
        replacedExisting: replaceExisting,
      ));
    } catch (e, stack) {
      debugPrint('[MENU IMPORT] Transaction failed: $e\n$stack');
      return Result.error(DatabaseFailure('Failed to import menu into database: ${e.toString()}'));
    }
  }
}
