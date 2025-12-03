import { Habit } from '../model/HabitModel';
import { AppColors, AppDimens, AppStrings } from '../common/Constants';
import { DateUtils } from '../common/Utils';

/**
 * 习惯卡片组件
 */
@Component
export struct HabitCard {
  @ObjectLink habit: Habit;
  @Prop isExpanded: boolean = false;
  onTap: () => void = () => {};
  onCheck: () => void = () => {};
  onToggleStatus: () => void = () => {};
  onDelete: () => void = () => {};
  onPin: () => void = () => {};
  onEdit: () => void = () => {};
  onDetail: () => void = () => {};

  build() {
    Column() {
      // 主内容区域
      Row() {
        // 打卡计数器
        this.Counter()

        // 文本内容
        Column() {
          Text(this.habit.name)
            .fontSize(AppDimens.FONT_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.habit.status === AppStrings.STATUS_STOPPED ? AppColors.TEXT_SECONDARY : AppColors.TEXT_PRIMARY)
            .decoration(this.habit.status === AppStrings.STATUS_STOPPED
              ? { type: TextDecorationType.LineThrough }
              : { type: TextDecorationType.None })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.habit.status === AppStrings.STATUS_STOPPED
            ? AppStrings.STATUS_STOPPED
            : `${AppStrings.LAST_COMPLETE}${DateUtils.formatRelativeDate(this.habit.getLastCompleteTime())}`)
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
          this.ActionButton($r('sys.media.ohos_ic_public_edit'), AppColors.PRIMARY, () => this.onEdit())
          this.ActionButton($r('sys.media.ohos_ic_public_list'), AppColors.PRIMARY, () => this.onDetail())
          this.ActionButton($r('sys.media.ohos_ic_public_push_pin'), AppColors.PRIMARY, () => this.onPin())
          this.ActionButton(
            this.habit.status === AppStrings.STATUS_STOPPED
              ? $r('sys.media.ohos_ic_public_play')
              : $r('sys.media.ohos_ic_public_pause'),
            AppColors.WARNING,
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
  Counter() {
    Column() {
      if (this.habit.totalDays > 0) {
        Text(`${this.habit.totalDays}`)
          .fontSize(AppDimens.FONT_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
    }
    .width(44)
    .height(44)
    .borderRadius(AppDimens.RADIUS_MEDIUM)
    .backgroundColor(this.habit.status === AppStrings.STATUS_STOPPED
      ? 'rgba(142, 142, 147, 0.1)'
      : (this.habit.totalDays > 0 ? AppColors.SUCCESS : Color.White))
    .border({
      width: 1.5,
      color: this.habit.status === AppStrings.STATUS_STOPPED
        ? 'rgba(142, 142, 147, 0.3)'
        : (this.habit.totalDays > 0 ? AppColors.SUCCESS : AppColors.BORDER_COLOR)
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 12 })
    .onClick(() => {
      if (this.habit.status !== AppStrings.STATUS_STOPPED) {
        this.onCheck();
      }
    })
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
