import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundamentzz/core/services/activation_service.dart';
import 'package:fundamentzz/core/services/app_data_storage_service.dart';
import 'package:fundamentzz/domain/entities/bill_customizer_settings.dart';
import 'package:fundamentzz/presentation/widgets/app_qr_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 1: One-Time Owner Activation Tests', () {
    late ActivationService activationService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      activationService = ActivationService(
        secureStorage: const FlutterSecureStorage(),
        appDataStorage: AppDataStorageService(),
      );
    });

    test('isActivated returns false initially on fresh install', () async {
      final activated = await activationService.isActivated();
      expect(activated, isFalse);
    });

    test('rejects incorrect activation codes', () async {
      expect(await activationService.verifyAndActivate(''), isFalse);
      expect(await activationService.verifyAndActivate('12345'), isFalse);
      expect(await activationService.verifyAndActivate('FZ-WRONG-CODE'), isFalse);
      expect(await activationService.verifyAndActivate('ADMIN123'), isFalse);

      // State remains unactivated
      expect(await activationService.isActivated(), isFalse);
    });

    test('accepts valid fixed owner code FZ-8899-PRO (case-insensitive & trimmed)', () async {
      final success = await activationService.verifyAndActivate('  fz-8899-pro  ');
      expect(success, isTrue);

      // Verify that activation state is securely stored and persists
      expect(await activationService.isActivated(), isTrue);
    });

    test('accepts valid fixed owner code FZ8899PRO without hyphens', () async {
      final success = await activationService.verifyAndActivate('FZ8899PRO');
      expect(success, isTrue);
      expect(await activationService.isActivated(), isTrue);
    });
  });

  group('Feature 2: Menu Export & Import ZIP Archive Tests', () {
    test('ZIP encoding and decoding roundtrip preserves menu.json and image bytes', () {
      final archive = Archive();

      // Mock menu data
      final menuData = {
        'format': 'fundamentzz_menu_archive',
        'version': 1,
        'categories': [
          {'id': 'cat_1', 'name': 'Coffee', 'icon': 'local_cafe', 'color_value': 4280172510},
        ],
        'products': [
          {
            'id': 'prod_1',
            'name': 'Espresso',
            'category_id': 'cat_1',
            'category_name': 'Coffee',
            'selling_price': 120.0,
            'cost_price': 30.0,
            'image_filename': 'espresso.jpg',
          },
        ],
      };

      final jsonBytes = utf8.encode(jsonEncode(menuData));
      archive.addFile(ArchiveFile('menu.json', jsonBytes.length, jsonBytes));

      // Mock sample dish image
      final mockImageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      archive.addFile(ArchiveFile('images/espresso.jpg', mockImageBytes.length, mockImageBytes));

      // Encode to ZIP
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      expect(zipBytes, isNotEmpty);

      // Decode from ZIP
      final decodedArchive = ZipDecoder().decodeBytes(zipBytes);
      expect(decodedArchive.files.length, equals(2));

      ArchiveFile? decodedMenuFile;
      ArchiveFile? decodedImgFile;

      for (final f in decodedArchive.files) {
        if (f.name == 'menu.json') decodedMenuFile = f;
        if (f.name == 'images/espresso.jpg') decodedImgFile = f;
      }

      expect(decodedMenuFile, isNotNull);
      expect(decodedImgFile, isNotNull);

      final decodedJson = jsonDecode(utf8.decode(decodedMenuFile!.content as List<int>)) as Map<String, dynamic>;
      expect(decodedJson['format'], equals('fundamentzz_menu_archive'));
      expect((decodedJson['products'] as List).first['name'], equals('Espresso'));
      expect((decodedJson['products'] as List).first['image_filename'], equals('espresso.jpg'));

      // Check image byte fidelity
      expect(decodedImgFile!.content as List<int>, equals(mockImageBytes));
    });

    test('corrupted or invalid ZIP bytes decode safely and missing menu.json is detected', () {
      final corruptedBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04, 0x05]);
      final archive = ZipDecoder().decodeBytes(corruptedBytes);
      final hasMenuJson = archive.files.any((f) => f.name == 'menu.json');
      expect(hasMenuJson, isFalse);
    });
  });

  group('Feature 3: Bill Customizer QR Code Settings & Widget Tests', () {
    test('BillCustomizerSettings showQrCode defaults to true', () {
      const cfg = BillCustomizerSettings();
      expect(cfg.showQrCode, isTrue);
    });

    test('BillCustomizerSettings copyWith toggles showQrCode', () {
      const original = BillCustomizerSettings();
      final toggledOff = original.copyWith(showQrCode: false);
      expect(toggledOff.showQrCode, isFalse);

      final toggledOn = toggledOff.copyWith(showQrCode: true);
      expect(toggledOn.showQrCode, isTrue);
    });

    test('BillCustomizerSettings toMap and fromMap serialization handles show_qr_code', () {
      const cfgOn = BillCustomizerSettings(showQrCode: true);
      final mapOn = cfgOn.toMap();
      expect(mapOn['show_qr_code'], equals(1));
      expect(BillCustomizerSettings.fromMap(mapOn).showQrCode, isTrue);

      const cfgOff = BillCustomizerSettings(showQrCode: false);
      final mapOff = cfgOff.toMap();
      expect(mapOff['show_qr_code'], equals(0));
      expect(BillCustomizerSettings.fromMap(mapOff).showQrCode, isFalse);

      // Graceful parsing when field is null or string
      expect(BillCustomizerSettings.fromMap({'show_qr_code': '1'}).showQrCode, isTrue);
      expect(BillCustomizerSettings.fromMap({'show_qr_code': '0'}).showQrCode, isFalse);
      expect(BillCustomizerSettings.fromMap({}).showQrCode, isTrue); // default
    });

    testWidgets('AppQrWidget renders without throwing errors for valid UPI payload', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppQrWidget(
                data: 'upi://pay?pa=fundamentzz@upi&pn=Fundamentzz%20Cafe&am=525.00&cu=INR',
                size: 120,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AppQrWidget), findsOneWidget);
    });

    testWidgets('AppQrWidget handles empty payload gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppQrWidget(
                data: '',
                size: 100,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
    });
  });
}
