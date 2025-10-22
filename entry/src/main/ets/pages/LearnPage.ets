import { PiDataManager } from '../utils/PiDataManager';
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct LearnPage {
  @State currentPosition: number = 1; // 当前遮罩位置（小数点后第n位）
  @State displayChars: string[] = [' ', ' ', ' ', ' ', '3', '.', '1', '4', '1', '5']; // 显示的字符（10个）
  @State offsetX: number = 0; // 滑动动画的偏移量
  @State refreshKey: number = 0; // 用于强制刷新UI
  @State pressedButton: number = -1; // 当前按下的按钮（-1表示无）
  @State isCorrect: boolean = false; // 当前按下的按钮是否正确

  private piManager: PiDataManager = PiDataManager.getInstance();
  private piData: string = ''; // 完整的圆周率数据
  private readonly CHAR_WIDTH = 50; // 每个字符的宽度
  private readonly VISIBLE_CHARS = 7; // 可见字符数
  private readonly TOTAL_CHARS = 10; // 总字符数（包含预备字符）
  private readonly MASK_INDEX = 4; // 遮罩位置（从0开始，第5个字符）
  
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

    // 立即更新显示
    this.updateDisplay();
  }
  
  /**
   * 更新显示内容
   * 显示10个字符，可见范围是7个字符（index 0-6）
   * 遮罩覆盖第5个可见字符（即displayChars的index=4）
   *
   * 示例：
   * position=1: displayChars=[' ', ' ', ' ', '3', '.', '1', '4', '1', '5', '9']
   *             可见：[' ', ' ', ' ', '3', '.', '1', '4']（index 0-6）
   *             遮罩覆盖index=4，即'.'... 不对！
   *
   * 重新计算：
   * position=1时，要遮罩小数第1位'1'
   * 可见应该是：[' ', '3', '.', '_', '4', '1', '5']
   * 所以displayChars应该是：[' ', '3', '.', '1', '4', '1', '5', '9', '2', '6']
   * 可见index 0-6，遮罩index=3
   *
   * 不对，让我重新设计：
   * 可见7个字符，遮罩在第4个（index=3）
   * position=1: 可见[' ', '3', '.', '_', '4', '1', '5']
   * displayChars=[' ', '3', '.', '1', '4', '1', '5', '9', '2', '6']
   * index 3对应position 1
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

    // index 0: currentPosition - 3
    // index 1: currentPosition - 2
    // index 2: currentPosition - 1
    // index 3: currentPosition (被遮罩)
    // index 4: currentPosition + 1
    // index 5: currentPosition + 2
    // index 6: currentPosition + 3
    // index 7: currentPosition + 4 (预备字符)
    // index 8: currentPosition + 5 (预备字符)
    // index 9: currentPosition + 6 (预备字符)

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
      } else {
        // 小数点后
        if (pos <= decimalPart.length) {
          chars.push(decimalPart.charAt(pos - 1));
        } else {
          chars.push(' ');
        }
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
   * 处理按钮按下
   */
  handleButtonDown(num: number) {
    this.pressedButton = num;
    const correctDigit = this.getCorrectDigit();
    this.isCorrect = (num.toString() === correctDigit);
  }

  /**
   * 处理按钮抬起
   */
  handleButtonUp(num: number) {
    this.pressedButton = -1;

    if (this.isCorrect) {
      // 输入正确，触发滑动动画
      this.animateSlide();
    } else {
      // 输入错误
      const correctDigit = this.getCorrectDigit();
      console.info(`Wrong input: expected ${correctDigit}, got ${num}`);
    }
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
   * 获取按钮背景色
   */
  getButtonBgColor(num: number): ResourceStr {
    if (this.pressedButton === num) {
      return this.isCorrect ? '#A5D6A7' : '#EF9A9A'; // 浅绿色或浅红色（降低饱和度）
    }
    return $r('app.color.button_background');
  }

  /**
   * 数字按钮
   */
  @Builder
  NumberButton(num: number) {
    Button(num.toString(), { type: ButtonType.Capsule, stateEffect: false })
      .fontSize(32)
      .width(80)
      .height(60)
      .margin({ left: 8, right: 8, top: 8, bottom: 8 })
      .backgroundColor(this.getButtonBgColor(num))
      .fontColor(this.pressedButton === num ? '#FFFFFF' : $r('app.color.text_primary'))
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.handleButtonDown(num);
        } else if (event.type === TouchType.Up) {
          this.handleButtonUp(num);
        }
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
  }
}

