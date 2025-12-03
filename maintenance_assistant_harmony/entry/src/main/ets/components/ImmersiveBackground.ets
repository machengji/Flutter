import { AppColors } from '../common/Constants';

/**
 * 沉浸式背景组件
 */
@Component
export struct ImmersiveBackground {
  build() {
    Stack() {
      // 基础渐变背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            [AppColors.BACKGROUND_PRIMARY, 0],
            [AppColors.BACKGROUND_SECONDARY, 1]
          ]
        })

      // 蓝色光晕 (左上)
      Column()
        .width(300)
        .height(300)
        .borderRadius(150)
        .radialGradient({
          center: [150, 150],
          radius: 150,
          colors: [
            ['rgba(0, 122, 255, 0.08)', 0],
            ['rgba(0, 122, 255, 0.04)', 0.5],
            ['rgba(0, 122, 255, 0)', 1]
          ]
        })
        .position({ x: -100, y: -150 })

      // 紫色光晕 (右上)
      Column()
        .width(200)
        .height(200)
        .borderRadius(100)
        .radialGradient({
          center: [100, 100],
          radius: 100,
          colors: [
            ['rgba(88, 86, 214, 0.06)', 0],
            ['rgba(88, 86, 214, 0.03)', 0.5],
            ['rgba(88, 86, 214, 0)', 1]
          ]
        })
        .position({ x: '80%', y: 150 })

      // 绿色光晕 (底部中间)
      Column()
        .width(250)
        .height(250)
        .borderRadius(125)
        .radialGradient({
          center: [125, 125],
          radius: 125,
          colors: [
            ['rgba(52, 199, 89, 0.05)', 0],
            ['rgba(52, 199, 89, 0.02)', 0.5],
            ['rgba(52, 199, 89, 0)', 1]
          ]
        })
        .position({ x: '30%', y: '80%' })

      // 顶部光线效果
      Column()
        .width('100%')
        .height('100%')
        .radialGradient({
          center: ['60%', '10%'],
          radius: '80%',
          colors: [
            ['rgba(255, 255, 255, 0.4)', 0],
            ['rgba(255, 255, 255, 0)', 0.4]
          ]
        })
    }
    .width('100%')
    .height('100%')
  }
}
