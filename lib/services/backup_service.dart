import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  /// Get the database file path
  static Future<String> _getDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'finance_app.db.sqlite');
  }

  /// EXPORT DB FILE
  static Future<void> exportBackup() async {
    try {
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception("Database file not found at $dbPath");
      }

      // Create a temp copy for sharing
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File(p.join(tempDir.path, "finance_backup_$timestamp.db"));

      await backupFile.writeAsBytes(await dbFile.readAsBytes());

      await Share.shareXFiles([XFile(backupFile.path)]);
    } catch (e) {
      print('Export error: $e');
      rethrow;
    }
  }

  /// IMPORT DB FILE
  static Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,  // Changed from FileType.custom
        allowMultiple: false,
      );

      if (result == null) return false;

      final pickedFile = File(result.files.single.path!);

      // Get the database path
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      // Delete old database
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // Copy new database
      await dbFile.writeAsBytes(await pickedFile.readAsBytes());

      return true;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }
}