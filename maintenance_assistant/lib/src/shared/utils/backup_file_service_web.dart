import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class BackupFileService {
  /// 网页端直接触发浏览器下载 .json 文件
  static Future<bool> exportBackupFile(String jsonContent, String fileName) async {
    try {
      final bytes = utf8.encode(jsonContent);
      final blob = html.Blob([bytes], 'application/json;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 网页端唤起文件选择框选择并读取 .json 文件
  static Future<String?> pickBackupFile() async {
    final completer = Completer<String?>();
    try {
      final uploadInput = html.FileUploadInputElement()
        ..accept = '.json,application/json'
        ..multiple = false;

      uploadInput.onChange.listen((event) {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) {
          if (!completer.isCompleted) completer.complete(null);
          return;
        }

        final file = files[0];
        final reader = html.FileReader();
        reader.onLoadEnd.listen((event) {
          final result = reader.result;
          if (result is String) {
            if (!completer.isCompleted) completer.complete(result);
          } else {
            if (!completer.isCompleted) completer.complete(null);
          }
        });
        reader.onError.listen((event) {
          if (!completer.isCompleted) completer.complete(null);
        });
        reader.readAsText(file);
      });

      uploadInput.click();
    } catch (e) {
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }
}
