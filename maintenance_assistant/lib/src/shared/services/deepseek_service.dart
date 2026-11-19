import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 智能 AI 服务（统一接入 DeepSeek 官方大语言模型，由服务端/编译期环境变量安全注入密钥，不对外暴露 Key 配置）
class DeepSeekService {
  /// DeepSeek 官方 API 端点（支持通过 --dart-define=DEEPSEEK_BASE_URL 切换为自有中转代理）
  static const String _envBaseUrl = String.fromEnvironment('DEEPSEEK_BASE_URL');
  static String get _baseUrl => _envBaseUrl.trim().isNotEmpty
      ? _envBaseUrl.trim()
      : 'https://api.deepseek.com/chat/completions';

  /// DeepSeek 模型名称（支持通过 --dart-define=DEEPSEEK_MODEL 覆盖）
  static const String _envModel = String.fromEnvironment('DEEPSEEK_MODEL');
  static String get _model =>
      _envModel.trim().isNotEmpty ? _envModel.trim() : 'deepseek-chat';

  /// 仅由编译期环境变量 --dart-define=DEEPSEEK_API_KEY=xxx 安全注入，严禁在源码中硬编码
  static const String _envApiKey = String.fromEnvironment('DEEPSEEK_API_KEY');

  DeepSeekService();

  static String _requireApiKey() {
    final key = _envApiKey.trim();
    if (key.isEmpty) {
      throw Exception('AI 服务暂未就绪，请稍后再试');
    }
    return key;
  }

  /// 深度分析用户全量或近期的计划、习惯及时间锚点数据，并生成生命六维度评分与全周期成长洞察
  Future<Map<String, dynamic>> analyzeData(Map<String, dynamic> data) async {
    final apiKey = _requireApiKey();

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
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
            }),
          )
          .timeout(const Duration(seconds: 25));

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
        throw Exception('DeepSeek API 请求失败：HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DeepSeekService.analyzeData 异常: $e');
      rethrow;
    }
  }

  /// 根据计划名称智能拆解出微习惯或行动标签列表
  Future<List<String>> getDeepseekBehaviors(String planName) async {
    final apiKey = _requireApiKey();

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
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
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;
        return content
            .split(RegExp(r'[,，、\n]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && !e.startsWith('-') && !e.startsWith('*'))
            .toList();
      } else {
        throw Exception('DeepSeek API 请求失败：HTTP ${response.statusCode} - ${response.body}');
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
    final apiKey = _requireApiKey();

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
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
            }),
          )
          .timeout(const Duration(seconds: 25));

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
        throw Exception('DeepSeek API 请求失败：HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DeepSeekService.analyzeSinglePlan 异常: $e');
      rethrow;
    }
  }

  /// 结合用户刚完成的具体事项名称，由 AI 实时生成量身定制的彩虹屁或冷笑话
  Future<String> generatePersonalizedCelebration({
    required String actionTitle,
    required bool preferColdJoke,
  }) async {
    final cleanTitle = actionTitle.trim();
    if (cleanTitle.isEmpty) {
      throw Exception('事项名称为空，无法生成定制庆祝语');
    }
    final apiKey = _requireApiKey();

    final systemPrompt = preferColdJoke
        ? '你是一位极具幽默感的中文冷笑话大师。用户刚刚完成了一件微行动，请你结合这件具体的事，创作 1 条简短、反转有趣、让人忍俊不禁的中文冷笑话来庆祝。要求：不超过 45 个汉字，直接输出冷笑话正文，不要加引号、序号或任何解释。'
        : '你是一位高情商、嘴超甜、懂福格微习惯的专属夸夸官。用户刚刚完成了一件微行动，请你紧扣这件具体的事，写 1 句极具画面感、让人嘴角上扬的专属彩虹屁。要求：不超过 45 个汉字，真诚又俏皮，直接输出正文，不要加引号、前缀或解释。';

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': '我刚刚完成了：$cleanTitle'},
            ],
            'temperature': 0.9,
            'max_tokens': 120,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('AI 定制请求失败：HTTP ${response.statusCode}');
    }
    final resData = jsonDecode(utf8.decode(response.bodyBytes));
    final content = (resData['choices']?[0]?['message']?['content'] ?? '')
        .toString()
        .trim()
        .replaceAll(RegExp(r'^[「『"“]+|[」』"”]+$'), '')
        .trim();
    if (content.isEmpty) {
      throw Exception('AI 返回内容为空');
    }
    return content;
  }

  /// 将用户的宏大或模糊目标，一键拆解为 3~5 个 2 分钟即可动手的微行动子步骤
  Future<List<String>> breakdownGoalToMicroSteps({
    required String goalTitle,
  }) async {
    final cleanGoal = goalTitle.trim();
    if (cleanGoal.isEmpty) {
      throw Exception('目标名称为空，无法拆解');
    }
    final apiKey = _requireApiKey();

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {
                'role': 'system',
                'content': '''
你是一位精通福格微习惯与 ADHD 友好型任务拆解的行动教练。
请将用户的目标拆解为 3 到 5 个极低门槛、2 分钟内就能马上动手的具体微行动步骤。
严格要求：
1. 必须仅返回纯 JSON 字符串数组，如 ["步骤1", "步骤2", "步骤3"]，禁止 Markdown 代码块或任何多余文字；
2. 每条步骤必须是具体动词开头，简洁明了，不超过 18 个汉字，按先后执行顺序排列。
''',
              },
              {'role': 'user', 'content': '请帮我把目标拆成微步骤：$cleanGoal'},
            ],
            'temperature': 0.7,
            'max_tokens': 300,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('AI 拆解请求失败：HTTP ${response.statusCode}');
    }

    final resData = jsonDecode(utf8.decode(response.bodyBytes));
    String content =
        (resData['choices']?[0]?['message']?['content'] ?? '').toString().trim();
    if (content.startsWith('```json')) {
      content = content.substring(7);
    } else if (content.startsWith('```')) {
      content = content.substring(3);
    }
    if (content.endsWith('```')) {
      content = content.substring(0, content.length - 3);
    }
    content = content.trim();

    final decoded = jsonDecode(content);
    if (decoded is! List) {
      throw Exception('AI 返回格式非步骤列表');
    }
    final steps = decoded
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .take(5)
        .toList();
    if (steps.isEmpty) {
      throw Exception('AI 未生成有效微步骤');
    }
    return steps;
  }
}
