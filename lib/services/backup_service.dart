// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Handles exporting a backup as a real `.json` file (opened in the system
/// share sheet immediately) and importing one back from the file picker.
///
/// No clipboard, no hidden storage — the user always chooses where the file
/// goes on export, and always picks the file on import.
class BackupService {
  BackupService._();

  /// Writes [payload] as pretty-printed JSON to the app's temp directory,
  /// then opens the Android / iOS share sheet so the user can save it to
  /// Files, Drive, WhatsApp, email, etc.
  ///
  /// Returns `true` if the share sheet reported success, `false` if the
  /// user cancelled or it failed.
  static Future<bool> exportBackup(
    Map<String, dynamic> payload, {
    String? subject,
  }) async {
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final dir = await getTemporaryDirectory();

    final now = DateTime.now();
    final stamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}';
    final fileName = 'universal_calendar_backup_$stamp.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json);

    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json', name: fileName)],
      subject: subject ?? 'Universal Calendar Backup',
    );

    // Best-effort cleanup — if share was successful or user cancelled,
    // either way the temp file is no longer needed.
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}

    return result.status == ShareResultStatus.success;
  }

  /// Opens the system file picker filtered to `.json` files. Returns the
  /// parsed payload, or `null` if the user cancelled.
  ///
  /// Throws [FormatException] if the picked file isn't a valid JSON object.
  static Future<Map<String, dynamic>?> pickAndReadBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final path = result.files.first.path;
    if (path == null) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    final decoded = json.decode(content);
    if (decoded is! Map) {
      throw const FormatException('Backup is not a JSON object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}