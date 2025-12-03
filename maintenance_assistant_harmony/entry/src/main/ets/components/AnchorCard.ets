import { Anchor } from '../model/AnchorModel';
import { AppColors, AppDimens, AppStrings } from '../common/Constants';

/**
 * 锚点卡片组件
 */
@Component
export struct AnchorCard {
  @ObjectLink anchor: Anchor;
  onTap: () => void = () => {};
  onEdit: () => void = () => {};
  onDelete: () => void = () => {};

  build() {
    Row() {
      // 时间显示
      Column() {
        Text(this.anchor.time)
          .fontSize(AppDimens.FONT_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(AppColors.BACKGROUND_PRIMARY)
      .borderRadius(AppDimens.RADIUS_SMALL)

      // 名称和关联项数量
      Column() {
        Text(this.anchor.name)
          .fontSize(AppDimens.FONT_LARGE)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.anchor.getItemCount()} ${AppStrings.LINKED_ITEMS}`)
          .fontSize(AppDimens.FONT_SMALL)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 16 })

      // 编辑按钮
      Column() {
        Image($r('sys.media.ohos_ic_public_edit'))
          .width(AppDimens.ICON_MEDIUM)
          .height(AppDimens.ICON_MEDIUM)
          .fillColor(AppColors.PRIMARY)
      }
      .width(36)
      .height(36)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.onEdit())
    }
    .width('100%')
    .padding(AppDimens.PADDING_LARGE)
    .backgroundColor(Color.White)
    .borderRadius(AppDimens.RADIUS_LARGE)
    .shadow({
      radius: 10,
      color: 'rgba(0, 0, 0, 0.05)',
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 12 })
    .onClick(() => this.onTap())
  }
}
