import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_data_storage_service.dart';

class ActivationService {
  final FlutterSecureStorage _secureStorage;
  final AppDataStorageService _appDataStorage;

  static const String _storageKey = 'fz_terminal_owner_activated_flag_v1';
  static const String _activationTokenKey = 'fz_terminal_activation_token_v1';
  static const String _salt = 'fz_pos_terminal_offline_salt_2026_x9';

  // Salted SHA-256 hashes for valid owner activation codes:
  // 1. "FZ-8899-PRO"
  // 2. "FZ8899PRO"
  static const List<String> _validHashes = [
    'e5495cbcacf88d35076333ae56782436168e6cc8c186a5a7603de3297e9e0cc5',
    '97ed9ff8f4c58fad47725025fccc8a36f9c454b6b2e73c5b644e6568cab6f8e0',
];

  ActivationService({
    FlutterSecureStorage? secureStorage,
    AppDataStorageService? appDataStorage,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _appDataStorage = appDataStorage ?? AppDataStorageService();

  /// Check if the terminal has already been activated
  Future<bool> isActivated() async {
    try {
      final value = await _secureStorage.read(key: _storageKey);
      if (value == 'true') {
        return true;
      }
    } catch (e) {
      debugPrint('[ACTIVATION] Error reading secure storage: $e');
    }

    // Fallback check in persistent app data if secure storage is unavailable
    try {
      final file = await _appDataStorage.loadPrinterSettings();
      if (file != null && file['terminal_activated'] == true) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Verify entered owner code and mark terminal as activated if correct
  Future<bool> verifyAndActivate(String rawCode) async {
    final cleanCode = rawCode.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;

    // Compute salted SHA-256 digest
    final bytes = utf8.encode('$_salt$cleanCode');
    final digest = sha256.convert(bytes).toString();

    bool isValid = false;
    for (final targetHash in _validHashes) {
      if (_constantTimeEquals(digest, targetHash)) {
        isValid = true;
        break;
      }
    }

    if (!isValid) {
      return false;
    }

    // Save activation state securely on device
    try {
      await _secureStorage.write(key: _storageKey, value: 'true');
      await _secureStorage.write(
        key: _activationTokenKey,
        value: digest,
      );
    } catch (e) {
      debugPrint('[ACTIVATION] Error writing secure storage: $e');
    }

    // Secondary persistent fallback
    try {
      final existing = await _appDataStorage.loadPrinterSettings() ?? {};
      existing['terminal_activated'] = true;
      await _appDataStorage.savePrinterSettings(existing);
    } catch (_) {}

    return true;
  }

  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  @visibleForTesting
  Future<void> resetActivationForTesting() async {
    try {
      await _secureStorage.delete(key: _storageKey);
      await _secureStorage.delete(key: _activationTokenKey);
    } catch (_) {}
  }
}
