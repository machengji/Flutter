import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeepSeekService {
  static const String _apiKeyKey = 'deepseekApiKey';
  static const String _apiUrl = 'https://api.deepseek.com/chat/completions';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key);
  }

  Future<List<String>> getDeepseekBehaviors(String goalName) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('MISSING_API_KEY');
    }

    final systemPrompt = '''
你将收到一个用户的"目标/愿望"。请基于这个目标，返回一个 JSON 对象，包含字段 "tags": string[]。
每个 tag 是一个可执行的、具体的行为建议（中文，简短动词短语），用于帮助用户达成目标。
重要：请优先推荐最容易开始的、门槛最低的行为，让用户能够立即行动起来。
请只返回 JSON，示例：{"tags":["行为1","行为2","行为3"]}
'''.trim();

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': goalName},
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        // Fix for UTF-8 decoding if needed, though http package usually handles it
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        final content = data['choices']?[0]['message']?['content'] ?? '{}';
        final parsed = jsonDecode(content);
        if (parsed['tags'] is List) {
          return List<String>.from(parsed['tags']);
        }
        return [];
      } else {
        throw Exception('API call failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch behaviors: $e');
    }
  }
}
