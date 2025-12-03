import { AppColors, AppDimens, AppStrings } from '../common/Constants';

/**
 * 添加/编辑弹窗组件
 */
@CustomDialog
export struct AddModal {
  controller: CustomDialogController;
  title: string = AppStrings.ADD_PLAN_TITLE;
  placeholder: string = AppStrings.ADD_PLAN_PLACEHOLDER;
  initialValue: string = '';
  onConfirm: (text: string) => void = () => {};

  @State inputText: string = '';

  aboutToAppear() {
    this.inputText = this.initialValue;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.title)
          .fontSize(AppDimens.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)

        Blank()

        Image($r('sys.media.ohos_ic_public_cancel'))
          .width(AppDimens.ICON_MEDIUM)
          .height(AppDimens.ICON_MEDIUM)
          .fillColor(AppColors.TEXT_SECONDARY)
          .padding(4)
          .backgroundColor('rgba(0, 0, 0, 0.05)')
          .borderRadius(12)
          .onClick(() => this.controller.close())
      }
      .width('100%')

      // 输入框
      TextInput({ placeholder: this.placeholder, text: this.inputText })
        .width('100%')
        .height(48)
        .fontSize(AppDimens.FONT_LARGE)
        .placeholderColor('rgba(0, 0, 0, 0.3)')
        .backgroundColor(Color.White)
        .borderRadius(AppDimens.RADIUS_MEDIUM)
        .border({
          width: 1,
          color: 'rgba(0, 122, 255, 0.2)'
        })
        .padding({ left: 16, right: 16 })
        .margin({ top: 24 })
        .onChange((value: string) => {
          this.inputText = value;
        })
        .onSubmit(() => {
          this.handleSubmit();
        })

      // 按钮区域
      Row() {
        Button(AppStrings.BUTTON_CANCEL)
          .width('48%')
          .height(44)
          .fontSize(AppDimens.FONT_LARGE)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .borderRadius(AppDimens.RADIUS_MEDIUM)
          .onClick(() => this.controller.close())

        Button(this.initialValue ? AppStrings.BUTTON_SAVE : AppStrings.BUTTON_ADD)
          .width('48%')
          .height(44)
          .fontSize(AppDimens.FONT_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(AppDimens.RADIUS_MEDIUM)
          .onClick(() => this.handleSubmit())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 24 })
    }
    .width('100%')
    .padding(AppDimens.PADDING_XLARGE)
    .backgroundColor('rgba(255, 255, 255, 0.95)')
    .borderRadius(AppDimens.RADIUS_XLARGE)
    .border({
      width: 1,
      color: 'rgba(0, 122, 255, 0.2)'
    })
    .shadow({
      radius: 12,
      color: 'rgba(0, 122, 255, 0.1)',
      offsetX: 0,
      offsetY: 8
    })
  }

  handleSubmit() {
    const trimmedText = this.inputText.trim();
    if (trimmedText.length > 0) {
      this.onConfirm(trimmedText);
      this.controller.close();
    }
  }
}
