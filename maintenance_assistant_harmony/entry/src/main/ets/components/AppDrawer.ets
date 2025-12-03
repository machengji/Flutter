import { AppColors, AppDimens, AppStrings } from '../common/Constants';

/**
 * 应用侧边栏组件
 */
@Component
export struct AppDrawer {
  onDataManagement: () => void = () => {};
  onDataAnalysis: () => void = () => {};
  onClose: () => void = () => {};

  build() {
    Column() {
      // 头部区域
      Column() {
        // Logo
        Column() {
          Text('🚀')
            .fontSize(32)
        }
        .width(64)
        .height(64)
        .backgroundColor(Color.White)
        .borderRadius(32)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 应用名称
        Text(AppStrings.APP_NAME)
          .fontSize(AppDimens.FONT_HEADER)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ top: 16 })

        // 副标题
        Text('让改变发生')
          .fontSize(AppDimens.FONT_MEDIUM)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .width('100%')
      .padding({ top: 60, left: 24, right: 24, bottom: 24 })
      .backgroundColor('#F5F5F7')
      .alignItems(HorizontalAlign.Start)

      // 菜单列表
      List() {
        ListItem() {
          this.MenuItem($r('sys.media.ohos_ic_public_import'), '数据管理', () => this.onDataManagement())
        }

        ListItem() {
          this.MenuItem($r('sys.media.ohos_ic_public_chart'), '数据分析', () => this.onDataAnalysis())
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ top: 16 })

      // 底部版本号
      Text('v1.0.0')
        .fontSize(AppDimens.FONT_SMALL)
        .fontColor('rgba(0, 0, 0, 0.2)')
        .padding(24)
    }
    .width('80%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  MenuItem(icon: Resource, label: string, onClick: () => void) {
    Row() {
      Image(icon)
        .width(22)
        .height(22)
        .fillColor(AppColors.TEXT_PRIMARY)

      Text(label)
        .fontSize(AppDimens.FONT_LARGE)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ left: 12 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 24, right: 24 })
    .onClick(() => onClick())
  }
}
