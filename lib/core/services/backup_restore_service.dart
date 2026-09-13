import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../errors/failures.dart';
import '../utils/result.dart';

class BackupRestoreService {
  Future<Result<String>> saveAndShareBackup(String jsonContent) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${tempDir.path}/fundamentzz_backup_$timestamp.json';
      final file = File(filePath);
      await file.writeAsString(jsonContent);

      final xFile = XFile(filePath);
      await Share.shareXFiles(
        [xFile],
        text: 'Fundamentzz POS Database Backup - $timestamp',
      );

      return Result.success(filePath);
    } catch (e) {
      return Result.error(BackupRestoreFailure(e.toString()));
    }
  }
}
