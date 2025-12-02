import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const String _prefsKey = 'deepseek_api_key';
  
  String? _apiKey;

  DeepSeekService() {
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_prefsKey);
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key);
    _apiKey = key;
  }

  Future<Map<String, dynamic>> analyzeData(Map<String, dynamic> data) async {
    await _ensureApiKeyLoaded();

    if (_apiKey == null || _apiKey!.isEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      return _getMockAnalysisJson();
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '''
你是一个专业的数据分析师。请分析用户的计划和习惯数据（最近30天）。
请返回纯 JSON 格式，不要包含 Markdown 代码块标记（如 ```json）。
JSON 结构如下：
{
  "summary": "一段简短的分析总结，包含鼓励和建议（支持 Markdown 格式）",
  "habit_rank": [
    {"name": "习惯名", "count": 30天打卡次数}
  ],
  "plan_stats": {
    "total": 总数,
    "completed": 完成数,
    "ongoing": 进行中数
  }
}
'''
            },
            {
              'role': 'user',
              'content': jsonEncode(data)
            }
          ],
          'temperature': 0.7,
          'response_format': {'type': 'json_object'}, // DeepSeek supports this
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(utf8.decode(response.bodyBytes));
        final content = resData['choices'][0]['message']['content'];
        try {
          final json = jsonDecode(content);
          // Clean up summary text (remove **)
          if (json['summary'] != null && json['summary'] is String) {
            json['summary'] = (json['summary'] as String).replaceAll('**', '');
          }
          return json;
        } catch (e) {
          // Fallback if content is not pure JSON
          return {
            'summary': content.replaceAll('**', ''),
            'habit_rank': [],
            'plan_stats': {'total': 0, 'completed': 0, 'ongoing': 0}
          };
        }
      } else {
        throw Exception('分析失败：${response.statusCode}');
      }
    } catch (e) {
      return {
        'summary': '发生错误：$e',
        'habit_rank': [],
        'plan_stats': {'total': 0, 'completed': 0, 'ongoing': 0}
      };
    }
  }

  Future<List<String>> getDeepseekBehaviors(String planName) async {
    await _ensureApiKeyLoaded();

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('MISSING_API_KEY');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '你是一个行为设计专家。请根据用户的计划，生成5-8个具体的、可执行的微习惯或行为标签。只返回标签列表，用逗号分隔，不要有其他废话。'
            },
            {
              'role': 'user',
              'content': '我的计划是：$planName'
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;
        // Split by comma and clean up
        return content.split(RegExp(r'[,，、\n]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get behaviors: $e');
    }
  }

  Future<void> _ensureApiKeyLoaded() async {
    if (_apiKey == null) {
      await _loadApiKey();
    }
  }

  Map<String, dynamic> _getMockAnalysisJson() {
    return {
      "summary": """
# 📊 数据分析报告

## 🌟 整体表现
你目前有 多个正在进行的计划 和 活跃的习惯，这显示了你积极向上的生活态度！

## 💡 亮点
- 你的习惯坚持得不错，继续保持！
- 计划列表井井有条。

## 🚀 建议
1. 专注一点：尝试优先完成一个最紧急的计划。
2. 习惯微调：如果某个习惯很难坚持，试着降低一点难度。

(注：这是模拟数据)
""",
      "habit_rank": [
        {"name": "早起", "count": 25},
        {"name": "阅读", "count": 18},
        {"name": "运动", "count": 12},
        {"name": "喝水", "count": 8}
      ],
      "plan_stats": {
        "total": 5,
        "completed": 2,
        "ongoing": 3
      }
    };
  }
}
