import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeanCloudBackupService {
  static const String _appId = 'fNJb5kxiG5JACBivlXAuGqly-gzGzoHsz';
  static const String _appKey = '0DF5TPnflU45HnbyFvVNPLxq';
  static const String _serverUrl = 'https://fnjb5kxi.lc-cn-n1-shared.com';
  static const String _className = 'MaintenanceAssistantBackup';
  static const String _syncKeyStorageKey = 'leancloud_sync_key';
  static const String _defaultBackupName = 'Maintenance Assistant Backup';

  Map<String, String> get _headers => const {
        'X-LC-Id': _appId,
        'X-LC-Key': _appKey,
        'Content-Type': 'application/json',
      };

  Uri _classesUri([String? objectId]) {
    final suffix = objectId == null ? '' : '/$objectId';
    return Uri.parse('$_serverUrl/1.1/classes/$_className$suffix');
  }

  Future<String> getSyncKey() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_syncKeyStorageKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final generated = _generateSyncKey();
    await prefs.setString(_syncKeyStorageKey, generated);
    return generated;
  }

  Future<void> setSyncKey(String syncKey) async {
    final trimmed = syncKey.trim();
    if (trimmed.isEmpty) {
      throw Exception('同步码不能为空');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncKeyStorageKey, trimmed);
  }

  Future<Map<String, dynamic>> saveBackup({
    required String dataJson,
    String? backupName,
    String? syncKey,
  }) async {
    final effectiveSyncKey =
        syncKey?.trim().isNotEmpty == true ? syncKey!.trim() : await getSyncKey();
    final existing = await _fetchLatestBackup(effectiveSyncKey);
    final payload = <String, dynamic>{
      'name': backupName ?? _defaultBackupName,
      'syncKey': effectiveSyncKey,
      'dataJson': dataJson,
      'schemaVersion': 1,
      'client': 'flutter',
    };

    if (existing == null) {
      final uri = _classesUri();
      debugPrint(
        '[LeanCloudBackup] POST $uri syncKey=$effectiveSyncKey bytes=${utf8.encode(dataJson).length}',
      );
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      );
      _ensureSuccess(response, 'POST', uri);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'syncKey': effectiveSyncKey,
        'objectId': body['objectId'],
        'createdAt': body['createdAt'],
      };
    }

    final objectId = existing['objectId'] as String;
    final uri = _classesUri(objectId);
    debugPrint(
      '[LeanCloudBackup] PUT $uri syncKey=$effectiveSyncKey bytes=${utf8.encode(dataJson).length}',
    );
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );
    _ensureSuccess(response, 'PUT', uri);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'syncKey': effectiveSyncKey,
      'objectId': objectId,
      'updatedAt': body['updatedAt'],
    };
  }

  Future<String?> loadBackupJson({String? syncKey}) async {
    final effectiveSyncKey =
        syncKey?.trim().isNotEmpty == true ? syncKey!.trim() : await getSyncKey();
    final backup = await _fetchLatestBackup(effectiveSyncKey);
    return backup?['dataJson'] as String?;
  }

  Future<Map<String, dynamic>?> _fetchLatestBackup(String syncKey) async {
    final uri = _classesUri().replace(
      queryParameters: {
        'where': jsonEncode({'syncKey': syncKey}),
        'order': '-updatedAt',
        'limit': '1',
      },
    );

    debugPrint('[LeanCloudBackup] GET $uri');
    final response = await http.get(uri, headers: _headers);
    _ensureSuccess(response, 'GET', uri);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? const []);
    if (results.isEmpty) {
      return null;
    }

    return results.first as Map<String, dynamic>;
  }

  void _ensureSuccess(http.Response response, String method, Uri uri) {
    debugPrint('[LeanCloudBackup] $method $uri -> ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    debugPrint('[LeanCloudBackup] response body: ${response.body}');

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['error']?.toString();
      final code = body['code']?.toString();
      if (message != null && message.isNotEmpty) {
        throw Exception(
          code != null ? 'LeanCloud $code: $message' : 'LeanCloud: $message',
        );
      }
    } on FormatException {
      // Ignore JSON parse errors and fall through to generic HTTP error.
    }

    throw Exception('LeanCloud request failed: ${response.statusCode}');
  }

  String _generateSyncKey() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = List.generate(8, (_) => random.nextInt(36).toRadixString(36)).join();
    return '$timestamp-$suffix'.toUpperCase();
  }
}
