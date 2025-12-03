import { AppColors, AppDimens } from '../common/Constants';
import { StringUtils } from '../common/Utils';
import { pasteboard } from '@kit.BasicServicesKit';

/**
 * 成功弹窗组件
 */
@CustomDialog
export struct SuccessPopup {
  controller: CustomDialogController;
  description: string = '';
  type: string = 'action'; // 'dream' | 'action'
  rainbowFart: string = '你今天闪闪发光！';
  onClose: () => void = () => {};

  build() {
    Stack() {
      // 背景遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .onClick(() => {
          this.onClose();
          this.controller.close();
        })

      // 卡片内容
      Column() {
        // 图标
        Column() {
          Text('🎉')
            .fontSize(36)
        }
        .width(70)
        .height(70)
        .backgroundColor(Color.White)
        .borderRadius(35)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .shadow({
          radius: 12,
          color: 'rgba(0, 0, 0, 0.08)',
          offsetX: 0,
          offsetY: 4
        })
        .offset({ y: -35 })

        // 标题
        Text('太棒了！')
          .fontSize(AppDimens.FONT_HEADER)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF9F0A')
          .margin({ top: -20 })

        // 彩虹屁引用框
        Column() {
          Text(this.rainbowFart)
            .fontSize(AppDimens.FONT_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .textAlign(TextAlign.Center)

          Row() {
            Image($r('sys.media.ohos_ic_public_copy'))
              .width(12)
              .height(12)
              .fillColor('#999999')
            Text('点此复制')
              .fontSize(AppDimens.FONT_SMALL)
              .fontColor('#999999')
              .margin({ left: 4 })
          }
          .margin({ top: 8 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFF5F7')
        .borderRadius(AppDimens.RADIUS_MEDIUM)
        .border({
          width: 1,
          color: 'rgba(255, 182, 193, 0.3)'
        })
        .margin({ top: 12 })
        .onClick(() => this.copyToClipboard())

        // 统计信息
        Row() {
          this.StatItem('成就徽章', this.type === 'dream' ? '梦想家 🏅' : '行动派 ⚡', '#FF9F0A')
          this.StatItem('本次记录', StringUtils.truncate(this.description, 4), AppColors.PRIMARY)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 16 })

        // 确认按钮
        Button() {
          Row() {
            Text('✌️')
              .fontSize(18)
            Text('收下这份喜悦')
              .fontSize(AppDimens.FONT_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ left: 8 })
          }
        }
        .width('100%')
        .height(48)
        .backgroundColor('#FF9A9E')
        .borderRadius(24)
        .margin({ top: 24 })
        .shadow({
          radius: 8,
          color: 'rgba(255, 154, 158, 0.4)',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          this.copyToClipboard();
          this.onClose();
          this.controller.close();
        })
      }
      .width('85%')
      .constraintSize({ maxWidth: 400 })
      .padding({ left: 24, right: 24, top: 24, bottom: 24 })
      .backgroundColor(Color.White)
      .borderRadius(AppDimens.RADIUS_XLARGE)
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 10
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  StatItem(label: string, value: string, valueColor: string) {
    Column() {
      Text(label)
        .fontSize(AppDimens.FONT_SMALL)
        .fontColor('#909399')

      Text(value)
        .fontSize(AppDimens.FONT_MEDIUM)
        .fontWeight(FontWeight.Bold)
        .fontColor(valueColor)
        .margin({ top: 4 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('48%')
    .padding(12)
    .backgroundColor('#F8F9FA')
    .borderRadius(AppDimens.RADIUS_MEDIUM)
  }

  copyToClipboard() {
    try {
      const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.rainbowFart);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setData(pasteboardData);
    } catch (err) {
      console.error('Copy to clipboard error:', JSON.stringify(err));
    }
  }
}
