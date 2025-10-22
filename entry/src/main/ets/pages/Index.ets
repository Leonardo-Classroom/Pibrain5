import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State highestRecord: number = 0;
  private dataPreferences?: preferences.Preferences;

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await this.initPreferences(context);
    this.highestRecord = await this.getHighestRecord();
  }

  async initPreferences(context: common.UIAbilityContext) {
    try {
      this.dataPreferences = await preferences.getPreferences(context, 'PiBrainPrefs');
    } catch (err) {
      console.error('Failed to initialize preferences: ' + JSON.stringify(err));
    }
  }

  async getHighestRecord(): Promise<number> {
    if (!this.dataPreferences) {
      return 0;
    }
    try {
      const record = await this.dataPreferences.get('testHighestRecord', 0) as number;
      return record;
    } catch (err) {
      console.error('Failed to get highest record: ' + JSON.stringify(err));
      return 0;
    }
  }

  openWebsite() {
    const context = getContext(this) as common.UIAbilityContext;
    const url = 'https://www.leonardo-classroom.com/';

    context.startAbility({
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    }).then(() => {
      console.info('Successfully opened website');
    }).catch((err: Error) => {
      console.error('Failed to open website: ' + JSON.stringify(err));
    });
  }

  build() {
    Stack() {
      // 主内容区域（垂直居中）
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
          .margin({ bottom: 10 })

        // 最高记录
        Text(`最高记录小数后${this.highestRecord}位`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 50 })

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
            router.pushUrl({
              url: 'pages/TestPage'
            });
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 作者链接（固定在底部）
      Column() {
        Text('点我看作者')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .onClick(() => {
            this.openWebsite();
          })
      }
      .width('100%')
      .padding({ bottom: 20 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Bottom)
    .backgroundColor($r('app.color.page_background'))
  }
}
