import { Plan } from '../model/PlanModel';
import { AppColors, AppDimens, AppStrings } from '../common/Constants';
import { DateUtils } from '../common/Utils';

/**
 * 计划卡片组件
 */
@Component
export struct PlanCard {
  @ObjectLink plan: Plan;
  @Prop isExpanded: boolean = false;
  onTap: () => void = () => {};
  onToggleStatus: () => void = () => {};
  onDelete: () => void = () => {};
  onPin: () => void = () => {};
  onEdit: () => void = () => {};
  onDetail: () => void = () => {};

  build() {
    Column() {
      // 主内容区域
      Row() {
        // 复选框
        this.CheckBox()

        // 文本内容
        Column() {
          Text(this.plan.name)
            .fontSize(AppDimens.FONT_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.plan.status === AppStrings.STATUS_COMPLETED
            ? `${AppStrings.COMPLETE_AT}${DateUtils.formatRelativeDate(this.plan.completeTime ?? 0)}`
            : DateUtils.formatRelativeDate(this.plan.createTime))
            .fontSize(AppDimens.FONT_SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 展开箭头
        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width(AppDimens.ICON_MEDIUM)
          .height(AppDimens.ICON_MEDIUM)
          .fillColor('#C7C7CC')
          .rotate({ angle: this.isExpanded ? 90 : 0 })
          .animation({ duration: 200 })
      }
      .width('100%')
      .padding(AppDimens.PADDING_MEDIUM)
      .onClick(() => this.onTap())

      // 操作按钮区域
      if (this.isExpanded) {
        Row() {
          this.ActionButton($r('sys.media.ohos_ic_public_list'), AppColors.PRIMARY, () => this.onDetail())
          this.ActionButton($r('sys.media.ohos_ic_public_edit'), AppColors.PRIMARY, () => this.onEdit())
          this.ActionButton($r('sys.media.ohos_ic_public_push_pin'), AppColors.PRIMARY, () => this.onPin())
          this.ActionButton(
            this.plan.status === AppStrings.STATUS_COMPLETED
              ? $r('sys.media.ohos_ic_public_refresh')
              : $r('sys.media.ohos_ic_public_ok'),
            this.plan.status === AppStrings.STATUS_COMPLETED ? AppColors.WARNING : AppColors.SUCCESS,
            () => this.onToggleStatus()
          )
          this.ActionButton($r('sys.media.ohos_ic_public_delete'), AppColors.DANGER, () => this.onDelete(), true)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .padding({ left: 10, right: 10, bottom: 10 })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(AppDimens.RADIUS_LARGE)
    .shadow({
      radius: 10,
      color: 'rgba(0, 122, 255, 0.08)',
      offsetX: 0,
      offsetY: 2
    })
    .border({
      width: 1,
      color: 'rgba(0, 122, 255, 0.1)'
    })
    .animation({ duration: 300 })
  }

  @Builder
  CheckBox() {
    Row() {
      if (this.plan.status === AppStrings.STATUS_COMPLETED) {
        Image($r('sys.media.ohos_ic_public_ok'))
          .width(16)
          .height(16)
          .fillColor(Color.White)
      }
    }
    .width(24)
    .height(24)
    .borderRadius(8)
    .backgroundColor(this.plan.status === AppStrings.STATUS_COMPLETED ? AppColors.PRIMARY : Color.White)
    .border({
      width: 1.5,
      color: this.plan.status === AppStrings.STATUS_COMPLETED ? AppColors.PRIMARY : AppColors.BORDER_COLOR
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .margin({ right: 12 })
    .onClick(() => this.onToggleStatus())
  }

  @Builder
  ActionButton(icon: Resource, color: string, onClick: () => void, isDanger: boolean = false) {
    Column() {
      Image(icon)
        .width(AppDimens.ICON_MEDIUM)
        .height(AppDimens.ICON_MEDIUM)
        .fillColor(color)
    }
    .width(40)
    .height(40)
    .borderRadius(AppDimens.RADIUS_MEDIUM)
    .backgroundColor(isDanger ? '#FFF5F5' : Color.White)
    .border({
      width: 1,
      color: isDanger ? 'rgba(255, 59, 48, 0.2)' : 'rgba(0, 122, 255, 0.1)'
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow({
      radius: 4,
      color: isDanger ? 'rgba(255, 59, 48, 0.05)' : 'rgba(0, 122, 255, 0.05)',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => onClick())
  }
}
