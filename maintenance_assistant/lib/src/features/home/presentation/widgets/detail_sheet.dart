import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/services/deepseek_service.dart';

class DetailSheet extends StatefulWidget {
  final String title;
  final String planName;
  final Function(String) onTagSelected;

  const DetailSheet({
    super.key,
    this.title = 'AI探索行为标签',
    required this.planName,
    required this.onTagSelected,
  });

  @override
  State<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<DetailSheet> {
  bool _isLoading = true;
  List<String> _tags = [];
  String? _error;
  final String _loadingText = 'tips：稍等10秒钟 有时候自己想到的行为才是最符合自己的哦';
  final DeepSeekService _deepSeekService = DeepSeekService();

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tags = await _deepSeekService.getDeepseekBehaviors(widget.planName);
      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('MISSING_API_KEY')) {
          _showApiKeyDialog();
        } else {
          setState(() {
            _error = '获取失败，请重试';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('设置 DeepSeek API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('需要 API Key 才能使用 AI 功能'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'sk-...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoading = false;
                _error = '未设置 API Key';
              });
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _deepSeekService.setApiKey(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadTags();
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 24),

          // Content
          SizedBox(
            height: 200,
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF007AFF)),
                        const SizedBox(height: 16),
                        // Tip removed as requested
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            TextButton(
                              onPressed: _loadTags,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _tags.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无探索标签',
                              style: TextStyle(color: Color(0xFF86868B)),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _tags.asMap().entries.map((entry) {
                                final index = entry.key;
                                final tag = entry.value;
                                return GestureDetector(
                                  onTap: () {
                                    widget.onTagSelected(tag);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF667EEA).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2, end: 0),
                                );
                              }).toList(),
                            ),
                          ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
