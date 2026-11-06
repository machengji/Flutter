import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/services/deepseek_service.dart';

/// 弹出智谱 GLM-4-Flash 密钥配置对话框
Future<void> showZhipuApiKeyDialog(
  BuildContext context, {
  VoidCallback? onSaved,
}) async {
  HapticFeedback.selectionClick();
  final currentKey = await DeepSeekService.getEffectiveApiKey();
  final controller = TextEditingController(text: currentKey);

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      bool isTesting = false;
      String? testMessage;
      bool? testSuccess;
      bool obscureKey = true;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const AppIcon(
                    type: AppIconType.apiKey,
                    size: 20,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '智谱 AI 密钥设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                          type: AppIconType.check,
                          size: 14,
                          color: Color(0xFF2D6A4F),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '模型：GLM-4-Flash（官方承诺永久免费）',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2D6A4F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '请输入您在智谱大模型开放平台的 API Key：',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    obscureText: obscureKey,
                    maxLines: 1,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '例如：d8a2...xxxxxxxx',
                      hintStyle: TextStyle(
                        color: AppColors.textHint.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border.withOpacity(0.3),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureKey ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureKey = !obscureKey;
                          });
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  if (testMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: (testSuccess == true ? AppColors.success : AppColors.error)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        testMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: testSuccess == true
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: 'https://open.bigmodel.cn'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已复制智谱官网链接（open.bigmodel.cn），请在浏览器中打开注册领取'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const AppIcon(
                      type: AppIconType.share,
                      size: 14,
                      color: Color(0xFF2D6A4F),
                    ),
                    label: const Text(
                      '复制智谱开放平台官网链接',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2D6A4F)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2D6A4F), width: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '免费获取步骤：\n'
                    '1. 手机或电脑浏览器访问 open.bigmodel.cn 并登录（支持微信扫码）；\n'
                    '2. 在右上角「控制台」-「API Keys」页面复制专属密钥；\n'
                    '3. 粘贴到上方输入框保存即可永久免费使用。',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isTesting
                    ? null
                    : () async {
                        setDialogState(() {
                          isTesting = true;
                          testMessage = '正在测试连接...';
                          testSuccess = null;
                        });
                        final res = await DeepSeekService.testConnection(
                          controller.text,
                        );
                        setDialogState(() {
                          isTesting = false;
                          testMessage = res['message'] as String;
                          testSuccess = res['success'] == true;
                        });
                      },
                child: Text(
                  isTesting ? '测试中...' : '测试连接',
                  style: const TextStyle(color: Color(0xFF2D6A4F)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await DeepSeekService.saveApiKey(controller.text);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('智谱 API Key 配置已保存'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  onSaved?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('保存配置'),
              ),
            ],
          );
        },
      );
    },
  );
}
