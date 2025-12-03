import { AppColors, AppDimens, AppStrings } from '../common/Constants';
import { DateUtils } from '../common/Utils';

/**
 * 添加/编辑锚点弹窗组件
 */
@CustomDialog
export struct AddAnchorModal {
  controller: CustomDialogController;
  initialName: string = '';
  initialTime: string = '08:00';
  onConfirm: (name: string, time: string) => void = () => {};

  @State inputName: string = '';
  @State selectedHour: number = 8;
  @State selectedMinute: number = 0;

  aboutToAppear() {
    this.inputName = this.initialName;
    if (this.initialTime) {
      const time = DateUtils.parseTime(this.initialTime);
      this.selectedHour = time.hour;
      this.selectedMinute = time.minute;
    }
  }

  build() {
    Column() {
      // 标题
      Text(this.initialName ? AppStrings.EDIT_ANCHOR_TITLE : AppStrings.ADD_ANCHOR_TITLE)
        .fontSize(AppDimens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .textAlign(TextAlign.Center)

      // 名称输入框
      TextInput({ placeholder: AppStrings.ADD_ANCHOR_PLACEHOLDER, text: this.inputName })
        .width('100%')
        .height(48)
        .fontSize(AppDimens.FONT_LARGE)
        .placeholderColor('rgba(134, 134, 139, 0.5)')
        .backgroundColor(AppColors.BACKGROUND_PRIMARY)
        .borderRadius(AppDimens.RADIUS_MEDIUM)
        .padding({ left: 16, right: 16 })
        .margin({ top: 24 })
        .onChange((value: string) => {
          this.inputName = value;
        })

      // 时间选择器
      Row() {
        Text('选择时间')
          .fontSize(AppDimens.FONT_LARGE)
          .fontColor(AppColors.TEXT_PRIMARY)

        Blank()

        Text(DateUtils.formatTime(this.selectedHour, this.selectedMinute))
          .fontSize(AppDimens.FONT_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.BACKGROUND_PRIMARY)
      .borderRadius(AppDimens.RADIUS_MEDIUM)
      .margin({ top: 16 })
      .onClick(() => {
        // 显示时间选择器
        TimePickerDialog.show({
          selected: new Date(2024, 0, 1, this.selectedHour, this.selectedMinute),
          useMilitaryTime: true,
          onAccept: (value: TimePickerResult) => {
            this.selectedHour = value.hour ?? 8;
            this.selectedMinute = value.minute ?? 0;
          }
        });
      })

      // 添加按钮
      Button(this.initialName ? AppStrings.BUTTON_SAVE : AppStrings.BUTTON_ADD)
        .width('100%')
        .height(48)
        .fontSize(AppDimens.FONT_LARGE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(AppDimens.RADIUS_MEDIUM)
        .margin({ top: 24 })
        .onClick(() => this.handleSubmit())
    }
    .width('100%')
    .padding(AppDimens.PADDING_XLARGE)
    .backgroundColor('rgba(255, 255, 255, 0.95)')
    .borderRadius(AppDimens.RADIUS_XLARGE)
    .shadow({
      radius: 20,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 10
    })
  }

  handleSubmit() {
    const trimmedName = this.inputName.trim();
    if (trimmedName.length > 0) {
      const timeStr = DateUtils.formatTime(this.selectedHour, this.selectedMinute);
      this.onConfirm(trimmedName, timeStr);
      this.controller.close();
    }
  }
}
