import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// App Store 上架合规：隐私政策与用户服务协议弹窗
class LegalSheet extends StatelessWidget {
  const LegalSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 16, 12),
            child: Row(
              children: [
                Text(
                  '隐私政策与用户协议',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: '1. 数据存储与本地优先原则',
                    body:
                        '「微行动助手」高度重视您的个人隐私。您的计划、子任务、习惯打卡记录、时间锚点及发光庆祝记录默认均仅保存在您的设备本地。您可随时在「数据管理」中导出完整 JSON 备份，或彻底清除本地数据。',
                  ),
                  _buildSection(
                    title: '2. 系统权限说明',
                    body:
                        '• 系统日历权限：仅在您开启「完成足迹自动记入日历」功能时使用，用于向您的专属「微行动」日历写入已完成事项记录。\n'
                        '• 系统提醒事项权限：仅在您启用双向同步或将计划加入提醒事项时使用，用于在「微行动」列表中同步待办状态。\n'
                        '• 本地通知权限：用于按您设定的时间锚点发送本地定时提醒。\n'
                        '• 相册写入权限：仅在您主动点击「保存发光海报」时使用，用于将海报图片保存至系统相册，我们不会读取您的相册内容。',
                  ),
                  _buildSection(
                    title: '3. 第三方接口与 AI 服务说明',
                    body:
                        '• 在线彩虹屁与冷笑话：仅通过加密 HTTPS 获取公开趣味文案，不向接口上传您的个人任务、身份或设备隐私信息。\n'
                        '• 智能 AI 助手（AI 定制庆祝语、AI 任务拆解与数据分析）：仅在您主动点击触发对应 AI 功能时，将您当前选择的任务名称或统计摘要发送至 DeepSeek 大语言模型服务接口以生成响应内容。',
                  ),
                  _buildSection(
                    title: '4. 用户服务协议与免责声明',
                    body:
                        '「微行动助手」是一款基于微习惯与积极自我肯定理念的个人行动辅助工具。AI 生成的拆解建议、庆祝语与成长分析仅供日常自我激励与效率参考，不构成医疗、心理诊疗或专业财务建议。',
                  ),
                  _buildSection(
                    title: '5. 联系与数据删除',
                    body:
                        '您拥有随时导出、修改或删除全部个人数据的权利。卸载应用将清除全部本地存储数据；如您使用过云端备份功能，可在「数据管理」中主动管理备份记录。',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
