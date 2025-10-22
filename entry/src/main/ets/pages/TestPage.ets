import { PiDataManager } from '../utils/PiDataManager';
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

@Entry
@Component
struct TestPage {
  @State currentPosition: number = 1; // 当前遮罩位置（小数点后第n位）
  @State displayChars: string[] = [' ', ' ', ' ', ' ', '3', '.', '1', '4', '1', '5']; // 显示的字符（10个）
  @State offsetX: number = 0; // 滑动动画的偏移量
  @State refreshKey: number = 0; // 用于强制刷新UI
  @State showGameOverDialog: boolean = false; // 显示游戏结束对话框
  @State finalPosition: number = 0; // 最终存活位置
  @State highestRecord: number = 0; // 最高记录
  @State isNewRecord: boolean = false; // 是否创下新记录

  private piManager: PiDataManager = PiDataManager.getInstance();
  private piData: string = ''; // 完整的圆周率数据
  private readonly CHAR_WIDTH = 50; // 每个字符的宽度
  private readonly VISIBLE_CHARS = 7; // 可见字符数
  private readonly TOTAL_CHARS = 10; // 总字符数（包含预备字符）
  private readonly MASK_INDEX = 4; // 遮罩位置（从0开始，第5个字符）
  private dataPreferences?: preferences.Preferences;

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await this.piManager.loadPiData(context);

    // 获取完整的圆周率数据
    const totalPages = this.piManager.getTotalPages();
    let fullData = '';
    for (let i = 0; i < totalPages; i++) {
      fullData += this.piManager.getPageData(i);
    }
    this.piData = fullData;

    console.info(`Pi data loaded successfully, length: ${this.piData.length}`);

    // 初始化Preferences并加载最高记录
    await this.initPreferences(context);
    this.highestRecord = await this.getHighestRecord();

    // 立即更新显示
    this.updateDisplay();
  }

  /**
   * 初始化Preferences
   */
  async initPreferences(context: common.UIAbilityContext) {
    try {
      this.dataPreferences = await preferences.getPreferences(context, 'PiBrainPrefs');
      console.info('Preferences initialized successfully');
    } catch (err) {
      console.error('Failed to initialize preferences: ' + JSON.stringify(err));
    }
  }

  /**
   * 获取最高记录
   */
  async getHighestRecord(): Promise<number> {
    if (!this.dataPreferences) {
      return 0;
    }
    try {
      const record = await this.dataPreferences.get('testHighestRecord', 0) as number;
      console.info(`Loaded highest record: ${record}`);
      return record;
    } catch (err) {
      console.error('Failed to get highest record: ' + JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 保存最高记录
   */
  async saveHighestRecord(record: number) {
    if (!this.dataPreferences) {
      return;
    }
    try {
      await this.dataPreferences.put('testHighestRecord', record);
      await this.dataPreferences.flush();
      console.info(`Saved highest record: ${record}`);
    } catch (err) {
      console.error('Failed to save highest record: ' + JSON.stringify(err));
    }
  }
  
  /**
   * 更新显示内容（测验模式）
   * 遮罩位置显示真实数字（被遮罩层覆盖），遮罩右方显示"?"
   */
  updateDisplay() {
    if (this.piData.length < 2) {
      return;
    }

    const chars: string[] = [];
    const decimalPart = this.piData.substring(2);

    // 构建10个字符的数组
    // 可见范围：index 0-6（7个字符）
    // 遮罩位置：index 3（可见的第4个字符）
    // index 3 对应 currentPosition（被遮罩的数字）

    for (let i = -3; i <= 6; i++) {
      const pos = this.currentPosition + i;

      if (pos <= 0) {
        // 小数点前
        if (pos === 0) {
          chars.push('.');
        } else if (pos === -1) {
          chars.push('3');
        } else {
          chars.push(' ');
        }
      } else if (i <= 0) {
        // 遮罩及左方：显示真实数字（遮罩位置的数字会被遮罩层覆盖）
        if (pos <= decimalPart.length) {
          chars.push(decimalPart.charAt(pos - 1));
        } else {
          chars.push(' ');
        }
      } else {
        // 遮罩右方：显示"?"
        chars.push('?');
      }
    }

    this.displayChars = [...chars];
    this.refreshKey++;

    console.info(`Position: ${this.currentPosition}`);
    console.info(`Display chars: [${chars.map(c => c === ' ' ? 'SPACE' : c).join(', ')}]`);
  }
  
  /**
   * 获取正确答案
   */
  getCorrectDigit(): string {
    const decimalPart = this.piData.substring(2);
    if (this.currentPosition > decimalPart.length) {
      return '';
    }
    return decimalPart.charAt(this.currentPosition - 1);
  }

  /**
   * 处理按钮点击（测验模式）
   */
  handleButtonClick(num: number) {
    const correctDigit = this.getCorrectDigit();

    if (num.toString() === correctDigit) {
      // 输入正确，触发滑动动画
      console.info(`Correct! Position: ${this.currentPosition}, will move to ${this.currentPosition + 1}`);
      this.animateSlide();
    } else {
      // 输入错误，显示游戏结束对话框
      console.info(`Wrong! Current position: ${this.currentPosition}, expected: ${correctDigit}, got: ${num}`);
      // 如果是第1位就答错，finalPosition=0；否则是currentPosition-1
      this.finalPosition = Math.max(0, this.currentPosition - 1);
      console.info(`Final position: ${this.finalPosition}`);
      this.showGameOver();
    }
  }

  /**
   * 显示游戏结束对话框
   */
  showGameOver() {
    // 检查是否创下新记录（在更新highestRecord之前判断）
    this.isNewRecord = (this.finalPosition > this.highestRecord || this.highestRecord === 0);

    if (this.isNewRecord) {
      this.highestRecord = this.finalPosition;
      this.saveHighestRecord(this.highestRecord);
    }

    this.showGameOverDialog = true;
  }

  /**
   * 滑动动画
   */
  animateSlide() {
    // 先向左滑动
    animateTo({
      duration: 300,
      curve: Curve.EaseOut,
      onFinish: () => {
        // 动画结束后，更新位置并重置偏移
        this.currentPosition++;
        this.offsetX = 0;
        this.updateDisplay();
      }
    }, () => {
      this.offsetX = -this.CHAR_WIDTH; // 向左滑动一个字符的宽度
    });
  }

  /**
   * 字符显示组件
   * @param char 要显示的字符
   * @param isMask 是否为遮罩字符
   */
  @Builder
  CharText(char: string, isMask: boolean) {
    Column() {
      Text() {
        Span((char === '' || char === null || char === undefined) ? '　' : char)
          .fontSize(48)
          .fontColor(isMask ? $r('app.color.accent_color') : $r('app.color.text_primary'))
          .fontFamily('monospace')
      }
      .width(this.CHAR_WIDTH)
      .height(60)
      .textAlign(TextAlign.Center)
      .onAppear(() => {
        if (!isMask) {
          console.info(`CharText appear: "${char}"`);
        }
      })
    }
    .width(this.CHAR_WIDTH)
    .height(60)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 数字按钮（测验模式 - 使用默认颜色）
   */
  @Builder
  NumberButton(num: number) {
    Button(num.toString(), { type: ButtonType.Capsule })
      .fontSize(32)
      .width(80)
      .height(60)
      .margin({ left: 8, right: 8, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.button_background'))
      .fontColor($r('app.color.text_primary'))
      .onClick(() => {
        this.handleButtonClick(num);
      })
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        // 返回按钮
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.accent_color')])
          .onClick(() => {
            router.back();
          })
          .margin({ right: 8 })
        
        Text(`小数后第${this.currentPosition}位`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        // 占位，保持标题居中
        Blank()
          .width(32)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor($r('app.color.header_background'))
      
      // 中间显示区域
      Column() {
        // 最高记录显示
        Text(`最高记录小数后${this.highestRecord}位`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 10 })

        Stack({ alignContent: Alignment.Start }) {
          // 滑动区块（10个字符）
          Row() {
            ForEach(this.displayChars, (char: string, index: number) => {
              this.CharText(char, false)
            }, (char: string, index: number) => `char-${index}-${this.refreshKey}`)
          }
          .width(this.CHAR_WIDTH * this.TOTAL_CHARS)
          .offset({ x: this.offsetX })

          // 遮罩层（覆盖第4个可见字符，即index=3）
          Row() {
            // 左侧空白（调整宽度以保持遮罩居中）
            Row().width(this.CHAR_WIDTH * 3 - this.CHAR_WIDTH * 0.25)

            // 左侧渐层
            Row()
              .width(this.CHAR_WIDTH * 0.25)
              .height(60)
              .linearGradient({
                direction: GradientDirection.Left,
                colors: [
                  [$r('app.color.gradient_solid'), 0.0],
                  [$r('app.color.gradient_transparent'), 1.0]
                ]
              })

            // 中间遮罩
            Column() {
              this.CharText('_', true)
            }
            .width(this.CHAR_WIDTH)
            .height(60)
            .backgroundColor($r('app.color.page_background')) // 使用背景色遮住下方数字

            // 右侧渐层
            Row()
              .width(this.CHAR_WIDTH * 0.25)
              .height(60)
              .linearGradient({
                direction: GradientDirection.Right,
                colors: [
                  [$r('app.color.gradient_solid'), 0.0],
                  [$r('app.color.gradient_transparent'), 1.0]
                ]
              })
          }
          .width(this.CHAR_WIDTH * this.VISIBLE_CHARS)
        }
        .width(this.CHAR_WIDTH * this.VISIBLE_CHARS) // 只显示7个字符（index 0-6）
        .clip(true) // 裁剪超出部分
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      
      // 底部数字键盘
      Column() {
        // 第一行：7, 8, 9
        Row() {
          this.NumberButton(7)
          this.NumberButton(8)
          this.NumberButton(9)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        
        // 第二行：4, 5, 6
        Row() {
          this.NumberButton(4)
          this.NumberButton(5)
          this.NumberButton(6)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        
        // 第三行：1, 2, 3
        Row() {
          this.NumberButton(1)
          this.NumberButton(2)
          this.NumberButton(3)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        
        // 第四行：空, 0, 空
        Row() {
          Blank()
            .layoutWeight(1)
          
          this.NumberButton(0)
          
          Blank()
            .layoutWeight(1)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 20, top: 20 })
      .backgroundColor($r('app.color.header_background'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .bindContentCover(this.showGameOverDialog, this.GameOverDialog(), {
      modalTransition: ModalTransition.DEFAULT
    })
  }

  /**
   * 游戏结束对话框
   */
  @Builder
  GameOverDialog() {
    Column() {
      Column() {
        // 标题
        Text('挑战结束')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 30 })

        // 存活位数
        Text(`存活到小数后第${this.finalPosition}位`)
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 15 })

        // 百分比
        Text(`占10万位的${(this.finalPosition / 100000 * 100).toFixed(3)}%`)
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 15 })

        // 记录信息
        if (this.isNewRecord) {
          Text('创下新记录！')
            .fontSize(18)
            .fontColor('#4CAF50')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 30 })
        } else if (this.finalPosition === this.highestRecord) {
          Text('追平最高记录！')
            .fontSize(18)
            .fontColor('#FF9800')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 30 })
        } else {
          Text(`距离最高记录差${this.highestRecord - this.finalPosition}位`)
            .fontSize(18)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 30 })
        }

        // 回目录按钮
        Button('回目录')
          .fontSize(18)
          .width('80%')
          .height(50)
          .onClick(() => {
            this.showGameOverDialog = false;
            router.back();
          })
      }
      .width('80%')
      .padding(30)
      .backgroundColor($r('app.color.page_background'))
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 点击背景不关闭对话框
    })
  }
}

