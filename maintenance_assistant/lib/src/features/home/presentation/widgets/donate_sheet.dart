import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../../core/theme/theme.dart';

/// 赞赏支持页面
/// 
/// 用于展示赞赏入口，支持微信、支付宝等方式
class DonateSheet extends StatefulWidget {
  const DonateSheet({super.key});

  @override
  State<DonateSheet> createState() => _DonateSheetState();
}

class _DonateSheetState extends State<DonateSheet> {
  int? _selectedAmount;
  
  final List<int> _amounts = [3, 6, 12, 20];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 48,
            height: 5,
            decoration: AppDecorations.dragHandleDecoration,
          ),
          const SizedBox(height: 24),
          
          // Coffee Icon with animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9A56), Color(0xFFFF6B35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '☕',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          ).scale(
            duration: 2.seconds,
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
          ),
          
          const SizedBox(height: 20),
          
          // Title
          Text(
            '请作者喝杯咖啡',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            '如果微行动对你有帮助\n可以考虑支持一下开发者 💝',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Amount Selection
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _amounts.map((amount) {
              final isSelected = _selectedAmount == amount;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedAmount = amount);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          )
                        : null,
                    color: isSelected ? null : AppColors.background,
                    borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppColors.border,
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Text(
                    '¥$amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 28),
          
          // Donate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedAmount != null 
                  ? () => _showPaymentOptions(context) 
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
                ),
                disabledBackgroundColor: AppColors.border,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    _selectedAmount != null 
                        ? '支持 ¥$_selectedAmount' 
                        : '选择金额',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Features unlocked message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('💡', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '微行动所有功能完全免费\n你的支持是我持续更新的动力',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Thank you message
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '下次一定 🙏',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentOptionsSheet(amount: _selectedAmount!),
    );
  }
}

/// 支付方式选择页面
class _PaymentOptionsSheet extends StatelessWidget {
  final int amount;

  const _PaymentOptionsSheet({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 48,
            height: 5,
            decoration: AppDecorations.dragHandleDecoration,
          ),
          const SizedBox(height: 20),
          
          Text(
            '选择支付方式',
            style: AppTextStyles.titleLarge,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '赞赏金额：¥$amount',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment Options
          _PaymentOption(
            icon: '💚',
            name: '微信支付',
            color: const Color(0xFF07C160),
            onTap: () => _handlePayment(context, 'wechat'),
          ),
          
          const SizedBox(height: 12),
          
          _PaymentOption(
            icon: '💙',
            name: '支付宝',
            color: const Color(0xFF1677FF),
            onTap: () => _handlePayment(context, 'alipay'),
          ),
          
          const SizedBox(height: 24),
          
          // Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDecorations.radiusSmall),
            ),
            child: Row(
              children: [
                const Text('💭', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '由于技术限制，暂时需要手动扫码支付\n感谢你的理解和支持！',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handlePayment(BuildContext context, String method) {
    // 显示收款码对话框
    final isWechat = method == 'wechat';
    final qrImage = isWechat 
        ? 'assets/images/wechat_pay_qr.png' 
        : 'assets/images/alipay_qr.png';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        title: Row(
          children: [
            Text(isWechat ? '💚' : '💙', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(isWechat ? '微信支付' : '支付宝'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 真实收款码图片 - 添加长按保存
            GestureDetector(
              onLongPress: () async {
                HapticFeedback.mediumImpact();
                try {
                  // 从 asset 加载图片数据
                  final ByteData bytes = await rootBundle.load(qrImage);
                  final Uint8List imageBytes = bytes.buffer.asUint8List();
                  
                  // 保存到相册
                  final result = await ImageGallerySaverPlus.saveImage(
                    imageBytes,
                    quality: 100,
                    name: isWechat ? 'wechat_pay_qr' : 'alipay_qr',
                  );
                  
                  if (context.mounted) {
                    if (result['isSuccess'] == true) {
                      _showOverlayToast(
                        context,
                        '✅ 已保存到相册',
                        isWechat ? const Color(0xFF07C160) : const Color(0xFF1677FF),
                      );
                    } else {
                      _showOverlayToast(
                        context,
                        '❌ 保存失败，请检查权限',
                        AppColors.error,
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showOverlayToast(
                      context,
                      '❌ 保存失败',
                      AppColors.error,
                    );
                  }
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  qrImage,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📱', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            '收款码加载失败',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isWechat ? const Color(0xFF07C160) : const Color(0xFF1677FF)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: isWechat ? const Color(0xFF07C160) : const Color(0xFF1677FF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '长按图片保存到相册',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isWechat ? const Color(0xFF07C160) : const Color(0xFF1677FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
              // 感谢提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Text('🙏', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('感谢你的支持！'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isWechat ? const Color(0xFF07C160) : const Color(0xFF1677FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('我已赞赏'),
          ),
        ],
      ),
    );
  }
}

/// 支付方式选项
class _PaymentOption extends StatelessWidget {
  final String icon;
  final String name;
  final Color color;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.name,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示 Overlay Toast 提示（不会被对话框遮挡）
void _showOverlayToast(BuildContext context, String message, Color backgroundColor) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
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
                color: backgroundColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
      ).animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: -0.3, end: 0, duration: 200.ms, curve: Curves.easeOut),
    ),
  );
  
  overlay.insert(overlayEntry);
  
  // 2秒后自动移除
  Future.delayed(const Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}
