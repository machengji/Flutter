import { hilog } from '@kit.PerformanceAnalysisKit';
import testsuite from '../../test/List.test';
import { Hypium } from '@ohos/hypium';

@Entry
@Component
struct Index {
  @State message: string = 'Hello Testing';

  aboutToAppear(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility index aboutToAppear');
    Hypium.hypiumTest(this.abilityContext, this.abilityStage, testsuite);
  }

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
        Text('Running tests...')
          .fontSize(20)
          .margin({ top: 20 })
      }
      .width('100%')
    }
    .height('100%')
  }
}
