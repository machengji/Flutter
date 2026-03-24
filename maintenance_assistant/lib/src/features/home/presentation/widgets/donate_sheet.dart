import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/utils/platform_image_save.dart';

class DonateSheet extends StatefulWidget {
  const DonateSheet({super.key});

  @override
  State<DonateSheet> createState() => _DonateSheetState();
}

class _DonateSheetState extends State<DonateSheet> {
  static const List<int> _amounts = [3, 6, 12, 20];

  int? _selectedAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
      decoration: AppDecorations.bottomSheetDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: AppDecorations.dragHandleDecoration,
          ),
          const SizedBox(height: 22),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF4FBF6), Color(0xFFE8F8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          )
              .animate()
              .fadeIn(duration: 280.ms)
              .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOut),
          const SizedBox(height: 18),
          Text(
            '支持一下这个小工具',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '你的支持会继续用在体验优化、细节打磨和后续功能迭代上。',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _amounts.map(_buildAmountChip).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
              boxShadow: AppDecorations.shadowButton,
            ),
            child: ElevatedButton(
              onPressed:
                  _selectedAmount == null ? null : () => _showPaymentOptions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textHint,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDecorations.radiusMedium),
                ),
              ),
              child: Text(
                _selectedAmount == null
                    ? '先选一个金额'
                    : '赞赏 ￥$_selectedAmount',
                style: AppTextStyles.button,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
              border: Border.all(color: AppColors.border.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '不会影响现有功能，纯自愿支持。',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '暂时不用',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChip(int amount) {
    final isSelected = _selectedAmount == amount;
    return InkWell(
      borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedAmount = amount);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
          border: Border.all(
            color:
                isSelected ? Colors.transparent : AppColors.border.withOpacity(0.9),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Text(
          '￥$amount',
          style: AppTextStyles.titleSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showPaymentOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentOptionsSheet(amount: _selectedAmount!),
    );
  }
}

class _PaymentOptionsSheet extends StatelessWidget {
  const _PaymentOptionsSheet({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
      decoration: AppDecorations.bottomSheetDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: AppDecorations.dragHandleDecoration,
          ),
          const SizedBox(height: 18),
          Text(
            '选择支付方式',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '本次赞赏金额 ￥$amount',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _PaymentOption(
            label: '微信',
            subtitle: '打开微信扫一扫',
            color: const Color(0xFF07C160),
            icon: Icons.chat_bubble_rounded,
            onTap: () => _showQrDialog(context, true),
          ),
          const SizedBox(height: 12),
          _PaymentOption(
            label: '支付宝',
            subtitle: '打开支付宝扫一扫',
            color: const Color(0xFF1677FF),
            icon: Icons.account_balance_wallet_rounded,
            onTap: () => _showQrDialog(context, false),
          ),
        ],
      ),
    );
  }

  void _showQrDialog(BuildContext context, bool isWechat) {
    final accentColor =
        isWechat ? const Color(0xFF07C160) : const Color(0xFF1677FF);
    final qrImage = isWechat
        ? 'assets/images/wechat_pay_qr.png'
        : 'assets/images/alipay_qr.png';
    final fileName = isWechat ? 'wechat_pay_qr.png' : 'alipay_pay_qr.png';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isWechat
                    ? Icons.chat_bubble_rounded
                    : Icons.account_balance_wallet_rounded,
                color: accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isWechat ? '微信赞赏' : '支付宝赞赏',
                style: AppTextStyles.titleMedium,
              ),
            ),
          ],
        ),
        content: _QrDialogContent(
          qrImage: qrImage,
          fileName: fileName,
          accentColor: accentColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '关闭',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              navigator.pop();
              navigator.pop();

              messenger.showSnackBar(
                SnackBar(
                  content: const Text('感谢支持，已经收到你的心意。'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('我已赞赏'),
          ),
        ],
      ),
    );
  }
}

class _QrDialogContent extends StatelessWidget {
  const _QrDialogContent({
    required this.qrImage,
    required this.fileName,
    required this.accentColor,
  });

  final String qrImage;
  final String fileName;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Text(
          kIsWeb ? '点击图片下载二维码' : '长按图片保存到相册',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: kIsWeb ? () => _saveQrImage(context) : null,
          onLongPress: kIsWeb ? null : () => _saveQrImage(context),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  qrImage,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Text(
                        '二维码资源加载失败',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => _saveQrImage(context),
          icon: Icon(
            kIsWeb ? Icons.download_rounded : Icons.photo_library_outlined,
            size: 18,
          ),
          label: Text(kIsWeb ? '下载二维码' : '保存到相册'),
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            side: BorderSide(color: accentColor.withOpacity(0.4)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _saveQrImage(BuildContext context) async {
    try {
      final bytes = await rootBundle.load(qrImage);
      final imageBytes = bytes.buffer.asUint8List();

      await saveImageToDevice(bytes: imageBytes, fileName: fileName);

      if (!context.mounted) {
        return;
      }

      _showOverlayToast(
        context,
        kIsWeb ? '二维码已开始下载' : '二维码已保存到相册',
        accentColor,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      _showOverlayToast(
        context,
        '当前平台暂时无法保存二维码',
        AppColors.error,
      );
    }
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

void _showOverlayToast(
  BuildContext context,
  String message,
  Color backgroundColor,
) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (_) => Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(begin: -0.25, end: 0, duration: 200.ms),
    ),
  );

  overlay.insert(overlayEntry);
  Future.delayed(const Duration(seconds: 2), overlayEntry.remove);
}
