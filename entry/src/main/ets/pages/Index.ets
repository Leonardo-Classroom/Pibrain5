import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  build() {
    Column() {
      // Logo
      Image($r('app.media.startIcon'))
        .width(120)
        .height(120)
        .margin({ bottom: 30 })

      // APP名称
      Text('Pi脑')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 60 })

      // 浏览圆周率按钮
      Button('浏览圆周率')
        .fontSize(20)
        .width('70%')
        .height(50)
        .margin({ bottom: 20 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/BrowsePage'
          });
        })

      // 学习圆周率按钮
      Button('学习圆周率')
        .fontSize(20)
        .width('70%')
        .height(50)
        .margin({ bottom: 20 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/LearnPage'
          });
        })

      // 测验圆周率按钮
      Button('测验圆周率')
        .fontSize(20)
        .width('70%')
        .height(50)
        .onClick(() => {
          // TODO: 导航到测验页面
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
