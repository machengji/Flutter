import { AppColors, AppDimens } from '../common/Constants';

/**
 * 空状态组件
 */
@Component
export struct EmptyState {
  icon: string = '✨';
  title: string = '';
  subtitle: string = '';

  build() {
    Column() {
      Text(this.icon)
        .fontSize(64)

      Text(this.title)
        .fontSize(AppDimens.FONT_XLARGE)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ top: 16 })

      Text(this.subtitle)
        .fontSize(AppDimens.FONT_MEDIUM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 100 })
    .alignItems(HorizontalAlign.Center)
  }
}
