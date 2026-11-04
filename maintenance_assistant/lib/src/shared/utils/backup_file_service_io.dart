import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/services/apple_eco_service.dart';

class BackupFileService {
  /// 导出 JSON 备份文件并通过系统面板分享/保存至本地
  static Future<bool> exportBackupFile(String jsonContent, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory('${tempDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final file = File('${backupDir.path}/$fileName');
      await file.writeAsString(jsonContent, encoding: utf8, flush: true);

      if (Platform.isIOS) {
        return await AppleEcoService().shareFile(file.path);
      }
      return true;
    } catch (e) {
      debugPrint('BackupFileService.exportBackupFile error: $e');
      return false;
    }
  }

  /// 唤起系统文件选择器并读取选中的 .json 备份文件内容
  static Future<String?> pickBackupFile() async {
    try {
      if (Platform.isIOS) {
        return await AppleEcoService().pickJsonFile();
      }
      return null;
    } catch (e) {
      debugPrint('BackupFileService.pickBackupFile error: $e');
      return null;
    }
  }
}
