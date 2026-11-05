import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 智能 AI 服务（内置官方高可用大模型通道，开箱即用免配 Key）
class DeepSeekService {
  /// 官方 API 端点
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  
  /// 官方大语言模型
  static const String _model = 'deepseek-chat';
  
  /// 内置真实可用的官方通道 Key（支持在编译或 CI 构建时通过 --dart-define=DEEPSEEK_API_KEY=xxx 覆盖）
  static const String _apiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: 'sk-4193c0275f5547469161e0af656acb5e',
  );

  DeepSeekService();

  /// 深度分析用户全量或近期的计划、习惯及时间锚点数据，并生成生命六维度评分与全周期成长洞察
  Future<Map<String, dynamic>> analyzeData(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
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
你是一个专业的数据分析师与个人成长导师。请分析用户的全量或近期任务与习惯数据。
请返回纯 JSON 格式，严格不要包含 Markdown 代码块标记（如 ```json）。
JSON 结构如下：
{
  "summary": "一段富有洞察力、兼具成就肯定与改进建议的分析总结（支持纯文本或简短换行）",
  "habit_rank": [
    {"name": "习惯名", "count": 历史打卡次数}
  ],
  "plan_stats": {
    "total": 计划总数,
    "completed": 已完成数,
    "ongoing": 进行中数,
    "completion_rate": "百分比字符串如 78%"
  },
  "life_dimensions": {
    "health": 评分(0-10),
    "family": 评分(0-10),
    "career": 评分(0-10),
    "wealth": 评分(0-10),
    "social": 评分(0-10),
    "growth": 评分(0-10)
  },
  "completed_milestones_summary": "一句话精炼总结用户已经取得的里程碑成就亮点",
  "focus_recommendation": "给用户接下来最具突破性的1-2个核心行动建议"
}
请根据计划和习惯的实际内容，自动归类到这6个维度（健康、家庭、事业、财富、社交、成长），并计算每个维度的投入度评分（0-10分）。
'''
                },
                {
                  'role': 'user',
                  'content': jsonEncode(data)
                }
              ],
              'temperature': 0.7,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 20));

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
        throw Exception('AI API 请求失败：HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DeepSeekService.analyzeData 异常: $e');
      rethrow;
    }
  }

  /// 根据计划名称智能拆解出微习惯或行动标签列表
  Future<List<String>> getDeepseekBehaviors(String planName) async {
    try {
      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;
        return content
            .split(RegExp(r'[,，、\n]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && !e.startsWith('-') && !e.startsWith('*'))
            .toList();
      } else {
        throw Exception('AI API 请求失败：HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DeepSeekService.getDeepseekBehaviors 异常: $e');
      rethrow;
    }
  }

  /// 专项深度剖析某个具体进入的任务：难度评估、卡点预测、3步破局路线、最佳时间锚点及微行动拆解
  Future<Map<String, dynamic>> analyzeSinglePlan({
    required String planName,
    String? status,
    List<String>? subtasks,
  }) async {
    try {
      final response = await http
          .post(
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
你是一个顶级的个人效能教练与行为设计专家（基于福格行为模型 BJ Fogg 与原子习惯）。
请针对用户当前进入的这项具体任务，进行深度剖析与落地攻克指导。
请返回纯 JSON 格式，严格不要包含 Markdown 代码块标记（如 ```json）。
JSON 格式如下：
{
  "task_name": "任务名称",
  "difficulty_level": "轻量行动 / 中度攻坚 / 长期战役",
  "difficulty_stars": 1到3的整数,
  "diagnosis": "一至两句精辟的心理与行动卡点诊断（指出该任务通常会在哪里受阻、拖延或感到阻力）",
  "recommended_anchor": "最适合触发该行动的日常时间锚点（例如：早晨第一杯咖啡后、下班进门换鞋时、睡前洗漱后）",
  "breakthrough_steps": [
    {"step": "第1步：5分钟破冰动作", "action": "具体微小、不可思议地容易执行的第一个动作"},
    {"step": "第2步：建立心流动量", "action": "推进核心交付的具体方法"},
    {"step": "第3步：达成闭环交付", "action": "如何定义完成并获得成就感正反馈"}
  ],
  "micro_behaviors": [
    "可拆解的微习惯1",
    "可拆解的微习惯2",
    "可拆解的微习惯3",
    "可拆解的微习惯4"
  ]
}
'''
                },
                {
                  'role': 'user',
                  'content': jsonEncode({
                    'task_name': planName,
                    'status': status ?? '进行中',
                    'subtasks': subtasks ?? [],
                  })
                }
              ],
              'temperature': 0.7,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final resData = jsonDecode(utf8.decode(response.bodyBytes));
        String content = resData['choices'][0]['message']['content'] ?? '';
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
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        throw Exception('AI API 请求失败：HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DeepSeekService.analyzeSinglePlan 异常: $e');
      rethrow;
    }
  }
}
