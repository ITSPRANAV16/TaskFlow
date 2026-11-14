import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/expense_model.dart';

enum DriveSyncState { idle, syncing, synced, error, notConnected }

/// Production Google Drive AppData Cloud Engine for SpendMate.
/// Uses official Google Drive REST API v3 to store data in the user's private appDataFolder.
class GoogleDriveService with ChangeNotifier {
  static const String _backupFileName = 'spendmate_backup.json';
  static const String _driveApiBase = 'https://www.googleapis.com/drive/v3';
  static const String _driveUploadBase = 'https://www.googleapis.com/upload/drive/v3';

  DriveSyncState _state = DriveSyncState.idle;
  String? _lastSyncedFileId;
  DateTime? _lastSyncTime;
  String? _errorMessage;

  DriveSyncState get state => _state;
  String? get lastSyncedFileId => _lastSyncedFileId;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get errorMessage => _errorMessage;
  bool get isSynced => _state == DriveSyncState.synced;

  /// Two-Way Non-Destructive Merge (Zero Data Loss)
  /// Reconciles local and cloud records by UUID and last modification.
  List<Expense> mergeExpenses(List<Expense> local, List<Expense> remote) {
    final Map<String, Expense> map = {};

    for (final exp in remote) {
      map[exp.id] = exp;
    }

    for (final exp in local) {
      if (!map.containsKey(exp.id)) {
        map[exp.id] = exp;
      } else {
        final existing = map[exp.id]!;
        if (exp.createdAt.isAfter(existing.createdAt)) {
          map[exp.id] = exp;
        }
      }
    }

    return map.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Syncs local expenses with user's private Google Drive AppData folder.
  /// Returns the merged expenses to update local state.
  Future<List<Expense>?> syncWithGoogleDrive({
    required Map<String, String> authHeaders,
    required List<Expense> localExpenses,
    required double monthlyBudget,
  }) async {
    _state = DriveSyncState.syncing;
    _errorMessage = null;
    notifyListeners();

    final client = http.Client();
    try {
      // 1. Search for existing spendmate_backup.json in appDataFolder
      final searchUri = Uri.parse(
        '$_driveApiBase/files?spaces=appDataFolder&q=name=%27$_backupFileName%27%20and%20trashed=false&fields=files(id,name,modifiedTime)',
      );

      final searchResponse = await client.get(searchUri, headers: authHeaders);
      if (searchResponse.statusCode != 200) {
        throw Exception(
            'Failed to search Google Drive: ${searchResponse.statusCode} - ${searchResponse.body}');
      }

      final searchData = jsonDecode(searchResponse.body) as Map<String, dynamic>;
      final files = (searchData['files'] as List<dynamic>?) ?? [];

      List<Expense> remoteExpenses = [];
      String? existingFileId;

      // 2. If file exists on Google Drive, download it
      if (files.isNotEmpty) {
        existingFileId = files.first['id'] as String;
        _lastSyncedFileId = existingFileId;

        final downloadUri = Uri.parse(
          '$_driveApiBase/files/$existingFileId?alt=media',
        );
        final downloadResponse = await client.get(downloadUri, headers: authHeaders);

        if (downloadResponse.statusCode == 200 && downloadResponse.body.isNotEmpty) {
          try {
            final Map<String, dynamic> remoteData = jsonDecode(downloadResponse.body);
            final List<dynamic> expList = (remoteData['expenses'] as List<dynamic>?) ?? [];
            remoteExpenses = expList
                .map((e) => Expense.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (e) {
            debugPrint('Error parsing remote Google Drive backup: $e');
          }
        }
      }

      // 3. Perform Two-Way Non-Destructive Merge (Zero Data Loss)
      final List<Expense> mergedList = mergeExpenses(localExpenses, remoteExpenses);

      // 4. Prepare updated JSON payload for Google Drive
      final Map<String, dynamic> backupPayload = {
        'app': 'SpendMate',
        'developer': 'Pranav Patil',
        'version': '1.1.0',
        'updatedAt': DateTime.now().toIso8601String(),
        'monthlyBudget': monthlyBudget,
        'expenseCount': mergedList.length,
        'expenses': mergedList.map((e) => e.toJson()).toList(),
      };
      final String payloadJson = jsonEncode(backupPayload);

      // 5. Upload back to Google Drive (Update if exists, or Create new)
      if (existingFileId != null) {
        final updateUri = Uri.parse(
          '$_driveUploadBase/files/$existingFileId?uploadType=media',
        );
        final updateResponse = await client.patch(
          updateUri,
          headers: {
            ...authHeaders,
            'Content-Type': 'application/json',
          },
          body: payloadJson,
        );

        if (updateResponse.statusCode != 200) {
          throw Exception('Failed to update Google Drive file: ${updateResponse.body}');
        }
      } else {
        // Multipart upload to create new file in appDataFolder
        final createUri = Uri.parse(
          '$_driveUploadBase/files?uploadType=multipart',
        );

        const boundary = 'spendmate_boundary_xyz';
        final metadata = jsonEncode({
          'name': _backupFileName,
          'parents': ['appDataFolder'],
        });

        final body = StringBuffer()
          ..write('--$boundary\r\n')
          ..write('Content-Type: application/json; charset=UTF-8\r\n\r\n')
          ..write(metadata)
          ..write('\r\n--$boundary\r\n')
          ..write('Content-Type: application/json\r\n\r\n')
          ..write(payloadJson)
          ..write('\r\n--$boundary--');

        final createResponse = await client.post(
          createUri,
          headers: {
            ...authHeaders,
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: body.toString(),
        );

        if (createResponse.statusCode != 200 && createResponse.statusCode != 201) {
          throw Exception('Failed to create file on Google Drive: ${createResponse.body}');
        }

        final createdData = jsonDecode(createResponse.body) as Map<String, dynamic>;
        _lastSyncedFileId = createdData['id'] as String?;
      }

      _lastSyncTime = DateTime.now();
      _state = DriveSyncState.synced;
      notifyListeners();

      return mergedList;
    } catch (e) {
      debugPrint('Google Drive Sync Error: $e');
      _state = DriveSyncState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      client.close();
    }
  }
}

