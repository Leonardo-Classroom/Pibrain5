import { PiDataManager, PageRange } from '../utils/PiDataManager';
import util from '@ohos.util';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State currentPage: number = 0;
  @State totalPages: number = 0;
  @State pageData: string = '';
  @State formattedLines: string[] = [];
  @State highlightPosition: number = -1; // 需要高亮的位数（小数点后）
  @State sliderValue: number = 0;

  private piManager: PiDataManager = PiDataManager.getInstance();
  private searchDialogController?: CustomDialogController;
  private pageJumpDialogController?: CustomDialogController;

  async aboutToAppear() {
    try {
      // 加载圆周率数据
      const context = getContext(this) as common.UIAbilityContext;
      await this.piManager.loadPiData(context);
      this.totalPages = this.piManager.getTotalPages();
      this.loadPage(0);
    } catch (err) {
      const error = err as Error;
      console.error('Failed to initialize: ' + error.message);
      promptAction.showToast({
        message: '加载数据失败',
        duration: 2000
      });
    }
  }

  /**
   * 加载指定页的数据
   */
  loadPage(pageIndex: number) {
    if (pageIndex < 0 || pageIndex >= this.totalPages) {
      console.error(`Invalid page index: ${pageIndex}, total pages: ${this.totalPages}`);
      return;
    }

    console.info(`Loading page ${pageIndex}`);
    this.currentPage = pageIndex;
    this.sliderValue = pageIndex;
    this.pageData = this.piManager.getPageData(pageIndex);
    this.formattedLines = this.piManager.formatPageData(this.pageData, pageIndex === 0);
    console.info(`Page loaded, lines: ${this.formattedLines.length}, data length: ${this.pageData.length}`);
  }

  /**
   * 跳转到指定位数
   */
  jumpToPosition(position: number) {
    console.info(`Jumping to position: ${position}`);
    const pageIndex = this.piManager.getPageByPosition(position);
    console.info(`Target page: ${pageIndex}`);
    this.highlightPosition = position;
    this.loadPage(pageIndex);
    console.info(`Highlight position set to: ${this.highlightPosition}`);
  }

  /**
   * 显示搜索对话框
   */
  showSearchDialog() {
    this.searchDialogController = new CustomDialogController({
      builder: SearchDialog({
        onConfirm: (position: number) => {
          this.jumpToPosition(position);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    this.searchDialogController.open();
  }

  /**
   * 显示页码跳转对话框
   */
  showPageJumpDialog() {
    this.pageJumpDialogController = new CustomDialogController({
      builder: PageJumpDialog({
        totalPages: this.totalPages,
        onConfirm: (pageIndex: number) => {
          this.highlightPosition = -1;
          this.loadPage(pageIndex);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    this.pageJumpDialogController.open();
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text() {
          Span($r('app.string.decimal_point_after'))
          Span(this.piManager.getPageRange(this.currentPage).start.toString())
          Span($r('app.string.to'))
          Span(this.piManager.getPageRange(this.currentPage).end.toString())
        }
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)

        Button($r('app.string.search'))
          .fontSize(16)
          .height(36)
          .onClick(() => {
            this.showSearchDialog();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#F5F5F5')

      // 圆周率显示区域
      Scroll() {
        Column() {
          ForEach(this.formattedLines, (line: string, lineIndex: number) => {
            this.buildLineText(line, lineIndex)
          }, (line: string, index: number) => `${this.currentPage}-${index}`)
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal })
          .onActionEnd((event: GestureEvent) => {
            if (event && event.offsetX) {
              if (event.offsetX > 50) {
                // 向右滑动，上一页
                if (this.currentPage > 0) {
                  this.highlightPosition = -1;
                  this.loadPage(this.currentPage - 1);
                }
              } else if (event.offsetX < -50) {
                // 向左滑动，下一页
                if (this.currentPage < this.totalPages - 1) {
                  this.highlightPosition = -1;
                  this.loadPage(this.currentPage + 1);
                }
              }
            }
          })
      )

      // 底部导航栏
      Column() {
        // 进度条
        Row() {
          Slider({
            value: this.sliderValue,
            min: 0,
            max: this.totalPages - 1,
            step: 1,
            style: SliderStyle.OutSet
          })
            .blockColor('#007DFF')
            .trackColor('#E5E5E5')
            .selectedColor('#007DFF')
            .showSteps(false)
            .showTips(false)
            .layoutWeight(1)
            .onChange((value: number) => {
              this.highlightPosition = -1;
              this.loadPage(Math.round(value));
            })

          // 页码显示和跳转
          Text(`${this.currentPage + 1}/${this.totalPages}`)
            .fontSize(16)
            .fontColor('#333333')
            .margin({ left: 12 })
            .onClick(() => {
              this.showPageJumpDialog();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .padding({ top: 12, bottom: 12 })
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * 构建单行文本，支持高亮
   */
  @Builder
  buildLineText(line: string, lineIndex: number) {
    Row() {
      ForEach(line.split(''), (char: string, charIndex: number) => {
        Text(char)
          .fontSize(48)
          .fontColor(this.shouldHighlight(this.getGlobalIndex(lineIndex, charIndex)) ? '#000000' : '#333333')
          .backgroundColor(this.shouldHighlight(this.getGlobalIndex(lineIndex, charIndex)) ? '#FFD700' : Color.Transparent)
          .padding({ left: 4, right: 4, top: 0, bottom: 0 })
          .fontFamily('monospace')
          .layoutWeight((lineIndex === 0 && this.currentPage === 0) ? 0 : 1)
          .textAlign(TextAlign.Center)
          .lineHeight(48)
          .width(this.shouldHighlight(this.getGlobalIndex(lineIndex, charIndex)) ? 56 : undefined)
          .height(this.shouldHighlight(this.getGlobalIndex(lineIndex, charIndex)) ? 56 : undefined)
          .borderRadius(this.shouldHighlight(this.getGlobalIndex(lineIndex, charIndex)) ? 28 : 0)
      }, (char: string, index: number) => `${this.currentPage}-${lineIndex}-${index}`)
    }
    .width('100%')
    .height(56)
    .margin({ bottom: 4 })
    .justifyContent((lineIndex === 0 && this.currentPage === 0) ? FlexAlign.Start : FlexAlign.SpaceEvenly)
  }

  /**
   * 获取字符的全局索引（在整个圆周率字符串中的位置）
   */
  getGlobalIndex(lineIndex: number, charIndex: number): number {
    let index = 0;
    for (let i = 0; i < lineIndex; i++) {
      index += this.formattedLines[i].length;
    }
    index += charIndex;
    return index;
  }

  /**
   * 判断是否应该高亮
   */
  shouldHighlight(globalIndex: number): boolean {
    if (this.highlightPosition <= 0) {
      return false;
    }

    const indexInPage = this.piManager.getIndexInPage(this.highlightPosition);
    const result = globalIndex === indexInPage;
    if (result) {
      console.info(`Highlighting at globalIndex: ${globalIndex}, indexInPage: ${indexInPage}, position: ${this.highlightPosition}`);
    }
    return result;
  }
}

/**
 * 搜索对话框
 */
@CustomDialog
struct SearchDialog {
  controller?: CustomDialogController;
  @State inputValue: string = '';
  onConfirm?: (position: number) => void;

  build() {
    Column() {
      Text($r('app.string.jump_to_position'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      TextInput({ placeholder: $r('app.string.enter_position') })
        .type(InputType.Number)
        .onChange((value: string) => {
          this.inputValue = value;
        })
        .margin({ bottom: 20 })

      Row() {
        Button($r('app.string.cancel'))
          .fontSize(16)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .layoutWeight(1)
          .onClick(() => {
            this.controller?.close();
          })

        Blank().width(12)

        Button($r('app.string.confirm'))
          .fontSize(16)
          .layoutWeight(1)
          .onClick(() => {
            console.info(`Search dialog input: ${this.inputValue}`);
            const position = parseInt(this.inputValue);
            console.info(`Parsed position: ${position}`);
            if (isNaN(position) || position <= 0) {
              console.error(`Invalid position: ${position}`);
              promptAction.showToast({
                message: $r('app.string.invalid_input'),
                duration: 2000
              });
              return;
            }

            console.info(`Calling onConfirm with position: ${position}`);
            if (this.onConfirm) {
              this.onConfirm(position);
            }
            this.controller?.close();
          })
      }
      .width('100%')
    }
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}

/**
 * 页码跳转对话框
 */
@CustomDialog
struct PageJumpDialog {
  controller?: CustomDialogController;
  @State inputValue: string = '';
  totalPages: number = 0;
  onConfirm?: (pageIndex: number) => void;

  build() {
    Column() {
      Text($r('app.string.jump_to_page'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      TextInput({ placeholder: $r('app.string.enter_page_number') })
        .type(InputType.Number)
        .onChange((value: string) => {
          this.inputValue = value;
        })
        .margin({ bottom: 20 })

      Row() {
        Button($r('app.string.cancel'))
          .fontSize(16)
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .layoutWeight(1)
          .onClick(() => {
            this.controller?.close();
          })

        Blank().width(12)

        Button($r('app.string.confirm'))
          .fontSize(16)
          .layoutWeight(1)
          .onClick(() => {
            const pageNum = parseInt(this.inputValue);
            if (isNaN(pageNum) || pageNum <= 0) {
              promptAction.showToast({
                message: $r('app.string.invalid_input'),
                duration: 2000
              });
              return;
            }

            const pageIndex = pageNum - 1;
            if (pageIndex >= this.totalPages) {
              promptAction.showToast({
                message: $r('app.string.page_out_of_range'),
                duration: 2000
              });
              return;
            }

            if (this.onConfirm) {
              this.onConfirm(pageIndex);
            }
            this.controller?.close();
          })
      }
      .width('100%')
    }
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}