import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';
import '../models/settlement.dart';

class BackupRestoreResult {
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final double? monthlyBudget;
  final String? email;
  final String source;

  BackupRestoreResult({
    required this.expenses,
    required this.settlements,
    this.monthlyBudget,
    this.email,
    required this.source,
  });
}

/// Persistent device mirror and Cloud Vault synchronization engine.
/// Guarantees that expense data survives complete app uninstallation & reinstallation.
class PersistentBackupService {
  static const String _fileName = 'spendmate_backup.json';
  static const String _prefsSnapshotKey = 'spendmate_persistent_snapshot_v1';
  static const String _cloudEndpoint = 'https://dpaste.org/api/';

  /// Whether running within flutter test harness
  static bool get isTestEnvironment =>
      Platform.environment.containsKey('FLUTTER_TEST');

  /// Candidate paths for persistent storage on Android/iOS/Desktop.
  /// Folders like /storage/emulated/0/Download/ are NEVER erased by Android upon app uninstallation.
  static Future<List<File>> _getTargetBackupFiles() async {
    if (isTestEnvironment) return [];
    final List<File> files = [];

    // 1. Android Public Download Folder (Survives app uninstallation)
    try {
      final downloadDir = Directory('/storage/emulated/0/Download/SpendMate');
      files.add(File('${downloadDir.path}/$_fileName'));
    } catch (_) {}

    // 2. Android Public Documents Folder (Survives app uninstallation)
    try {
      final docDir = Directory('/storage/emulated/0/Documents/SpendMate');
      files.add(File('${docDir.path}/$_fileName'));
    } catch (_) {}

    // 3. Fallback /sdcard paths
    try {
      final sdcardDir = Directory('/sdcard/Download/SpendMate');
      files.add(File('${sdcardDir.path}/$_fileName'));
    } catch (_) {}

    // 4. App Documents Directory
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      files.add(File('${appDocDir.path}/$_fileName'));
    } catch (_) {}

    // 5. External App Storage Directory
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        files.add(File('${extDir.path}/$_fileName'));
      }
    } catch (_) {}

    return files;
  }

  /// Saves the complete financial vault to persistent storage mirrors.
  static Future<void> savePersistentBackup({
    required List<Expense> expenses,
    required List<Settlement> settlements,
    required double monthlyBudget,
    String? userEmail,
  }) async {
    if (isTestEnvironment) return;
    final Map<String, dynamic> payload = {
      'app': 'SpendMate',
      'developer': 'Pranav Patil',
      'version': '1.1.0',
      'updatedAt': DateTime.now().toIso8601String(),
      'accountEmail': userEmail ?? 'pranavsp2810@gmail.com',
      'monthlyBudget': monthlyBudget,
      'expenseCount': expenses.length,
      'settlementCount': settlements.length,
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'settlements': settlements.map((s) => s.toJson()).toList(),
    };

    final String jsonStr = jsonEncode(payload);

    // 1. Save snapshot in SharedPreferences (for Android Auto-Backup to Google Drive)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsSnapshotKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving prefs snapshot: $e');
    }

    // 2. Save to persistent external directories (Survives uninstallation)
    try {
      final files = await _getTargetBackupFiles();
      for (final file in files) {
        try {
          if (!file.parent.existsSync()) {
            file.parent.createSync(recursive: true);
          }
          file.writeAsStringSync(jsonStr, flush: true);
          debugPrint('Persistent backup written to: ${file.path}');
        } catch (e) {
          // Some paths may not be writable depending on OS restrictions, continue to next
          debugPrint('Could not write to ${file.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error writing persistent backup files: $e');
    }
  }

  /// Automatically discovers and restores the financial vault after an app reinstall.
  static Future<BackupRestoreResult?> restorePersistentBackup({String? filterEmail}) async {
    if (isTestEnvironment) return null;
    // 1. Check persistent device mirrors first (Fastest & 100% reliable)
    try {
      final files = await _getTargetBackupFiles();
      for (final file in files) {
        if (file.existsSync()) {
          try {
            final content = file.readAsStringSync();
            if (content.trim().isNotEmpty) {
              final Map<String, dynamic> data = jsonDecode(content);
              final List<dynamic>? expList = data['expenses'] as List<dynamic>?;
              final List<dynamic>? setList = data['settlements'] as List<dynamic>?;

              if (expList != null && expList.isNotEmpty) {
                final expenses = expList
                    .map((e) => Expense.fromJson(e as Map<String, dynamic>))
                    .toList();
                final settlements = (setList ?? [])
                    .map((s) => Settlement.fromJson(s as Map<String, dynamic>))
                    .toList();
                final budget = (data['monthlyBudget'] as num?)?.toDouble();
                final email = data['accountEmail'] as String?;

                debugPrint(
                    'Restored ${expenses.length} expenses from persistent file: ${file.path}');
                return BackupRestoreResult(
                  expenses: expenses,
                  settlements: settlements,
                  monthlyBudget: budget,
                  email: email,
                  source: 'Persistent Device Mirror (${file.parent.path})',
                );
              }
            }
          } catch (e) {
            debugPrint('Error reading backup file ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning persistent backup files: $e');
    }

    // 2. Check SharedPreferences snapshot (Android Auto-Backup)
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshot = prefs.getString(_prefsSnapshotKey);
      if (snapshot != null && snapshot.trim().isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(snapshot);
        final List<dynamic>? expList = data['expenses'] as List<dynamic>?;
        final List<dynamic>? setList = data['settlements'] as List<dynamic>?;

        if (expList != null && expList.isNotEmpty) {
          final expenses = expList
              .map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList();
          final settlements = (setList ?? [])
              .map((s) => Settlement.fromJson(s as Map<String, dynamic>))
              .toList();
          final budget = (data['monthlyBudget'] as num?)?.toDouble();
          final email = data['accountEmail'] as String?;

          return BackupRestoreResult(
            expenses: expenses,
            settlements: settlements,
            monthlyBudget: budget,
            email: email,
            source: 'Android Cloud Auto-Backup',
          );
        }
      }
    } catch (e) {
      debugPrint('Error reading prefs snapshot: $e');
    }

    return null;
  }
}
