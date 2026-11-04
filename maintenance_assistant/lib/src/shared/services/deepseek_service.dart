import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 智能 AI 服务（基于智谱 GLM-4-Flash 永久免费开放模型）
class DeepSeekService {
  /// 智谱开放平台官方 API 端点
  static const String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  
  /// 智谱官方永久免费大模型
  static const String _model = 'glm-4-flash';
  
  /// 内置官方免费开放 API Key（支持在编译或 CI 构建时通过 --dart-define=ZHIPU_API_KEY=xxx 注入）
  static const String _apiKey = String.fromEnvironment(
    'ZHIPU_API_KEY',
    defaultValue: 'c4e3650212354c46ba86db3e67123984.pA1d9fB2e6q58v9K',
  );

  DeepSeekService();

  /// 深度分析用户近 30 天计划和打卡数据并生成生活六维度评分
  Future<Map<String, dynamic>> analyzeData(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
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
  },
  "life_dimensions": {
    "health": 评分(0-10),
    "family": 评分(0-10),
    "career": 评分(0-10),
    "wealth": 评分(0-10),
    "social": 评分(0-10),
    "growth": 评分(0-10)
  }
}
请根据计划和习惯的内容，自动归类到这6个维度（健康、家庭、事业、财富、社交、成长），并计算每个维度的投入度评分（0-10分）。
'''
            },
            {
              'role': 'user',
              'content': jsonEncode(data)
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(utf8.decode(response.bodyBytes));
        String content = resData['choices'][0]['message']['content'] ?? '';
        
        // 清洗可能附带的 Markdown 代码块标记
        content = content.trim();
        if (content.startsWith('```json')) {
          content = content.substring(7);
        } else if (content.startsWith('```')) {
          content = content.substring(3);
        }
        if (content.endsWith('```')) {
          content = content.substring(0, content.length - 3);
        }
        content = content.trim();

        final json = jsonDecode(content) as Map<String, dynamic>;
        if (json['summary'] != null && json['summary'] is String) {
          json['summary'] = (json['summary'] as String).replaceAll('**', '');
        }
        return json;
      } else {
        throw Exception('智谱 API 请求失败：HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DeepSeekService.analyzeData 异常: $e');
      rethrow;
    }
  }

  /// 根据计划名称智能拆解出微习惯或行动标签列表
  Future<List<String>> getDeepseekBehaviors(String planName) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
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
        return content
            .split(RegExp(r'[,，、\n]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && !e.startsWith('-') && !e.startsWith('*'))
            .toList();
      } else {
        throw Exception('智谱 API 请求失败：HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DeepSeekService.getDeepseekBehaviors 异常: $e');
      rethrow;
    }
  }
}
