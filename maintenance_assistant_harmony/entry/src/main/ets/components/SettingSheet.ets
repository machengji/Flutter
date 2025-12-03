import { AppColors, AppDimens, AppStrings } from '../common/Constants';
import { pasteboard } from '@kit.BasicServicesKit';

/**
 * 设置面板组件
 */
@CustomDialog
export struct SettingSheet {
  controller: CustomDialogController;
  exportData: string = '';
  onImport: (data: string) => void = () => {};

  @State importText: string = '';
  @State showImportInput: boolean = false;

  build() {
    Column() {
      // 标题
      Row() {
        Text('数据管理')
          .fontSize(AppDimens.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)

        Blank()

        Image($r('sys.media.ohos_ic_public_cancel'))
          .width(AppDimens.ICON_MEDIUM)
          .height(AppDimens.ICON_MEDIUM)
          .fillColor(AppColors.TEXT_SECONDARY)
          .onClick(() => this.controller.close())
      }
      .width('100%')
      .padding({ bottom: 24 })

      // 导出数据按钮
      Button() {
        Row() {
          Image($r('sys.media.ohos_ic_public_upload'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
          Text('导出数据')
            .fontSize(AppDimens.FONT_LARGE)
            .fontColor(Color.White)
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor(AppColors.PRIMARY)
      .borderRadius(AppDimens.RADIUS_MEDIUM)
      .onClick(() => this.handleExport())

      // 导入数据按钮
      Button() {
        Row() {
          Image($r('sys.media.ohos_ic_public_download'))
            .width(20)
            .height(20)
            .fillColor(AppColors.PRIMARY)
          Text('导入数据')
            .fontSize(AppDimens.FONT_LARGE)
            .fontColor(AppColors.PRIMARY)
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor(Color.White)
      .borderRadius(AppDimens.RADIUS_MEDIUM)
      .border({
        width: 1,
        color: AppColors.PRIMARY
      })
      .margin({ top: 12 })
      .onClick(() => {
        this.showImportInput = !this.showImportInput;
      })

      // 导入输入框
      if (this.showImportInput) {
        Column() {
          TextArea({ placeholder: '粘贴导出的JSON数据...', text: this.importText })
            .width('100%')
            .height(120)
            .fontSize(AppDimens.FONT_MEDIUM)
            .backgroundColor(AppColors.BACKGROUND_PRIMARY)
            .borderRadius(AppDimens.RADIUS_MEDIUM)
            .onChange((value: string) => {
              this.importText = value;
            })

          Button('确认导入')
            .width('100%')
            .height(44)
            .fontSize(AppDimens.FONT_LARGE)
            .fontColor(Color.White)
            .backgroundColor(AppColors.SUCCESS)
            .borderRadius(AppDimens.RADIUS_MEDIUM)
            .margin({ top: 12 })
            .onClick(() => this.handleImport())
        }
        .width('100%')
        .margin({ top: 16 })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }

      // 说明文字
      Text('导出的数据可以用于备份或迁移到其他设备')
        .fontSize(AppDimens.FONT_SMALL)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .margin({ top: 24 })
    }
    .width('100%')
    .padding(AppDimens.PADDING_XLARGE)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: AppDimens.RADIUS_XLARGE, topRight: AppDimens.RADIUS_XLARGE })
  }

  handleExport() {
    try {
      const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.exportData);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setData(pasteboardData);
      // 提示用户数据已复制
    } catch (err) {
      console.error('Export error:', JSON.stringify(err));
    }
  }

  handleImport() {
    if (this.importText.trim().length > 0) {
      this.onImport(this.importText.trim());
      this.controller.close();
    }
  }
}
