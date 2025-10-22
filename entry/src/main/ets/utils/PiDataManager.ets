import util from '@ohos.util';

/**
 * 页面范围接口
 */
export interface PageRange {
  start: number;
  end: number;
}

/**
 * 圆周率数据管理类
 * 负责分页加载和管理圆周率数据
 */
export class PiDataManager {
  private static instance: PiDataManager;
  private piData: string = '';
  private isLoaded: boolean = false;
  
  // 每页显示的数字数量
  public static readonly DIGITS_PER_PAGE = 56;
  // 第一页的数字数量（第一行"3."，后面7行每行7个，共49个，加上"3."总共51个字符，但小数部分是56个）
  public static readonly FIRST_PAGE_DIGITS = 56;
  // 每行显示的数字数量
  public static readonly DIGITS_PER_LINE = 7;
  // 每页显示的行数
  public static readonly LINES_PER_PAGE = 8;
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  public static getInstance(): PiDataManager {
    if (!PiDataManager.instance) {
      PiDataManager.instance = new PiDataManager();
    }
    return PiDataManager.instance;
  }
  
  /**
   * 加载圆周率数据
   */
  public async loadPiData(context: Context): Promise<void> {
    if (this.isLoaded) {
      return;
    }
    
    try {
      // 从rawfile目录读取pi.txt
      const filePath = 'pi.txt';
      const fileData = await context.resourceManager.getRawFileContent(filePath);
      const decoder = util.TextDecoder.create('utf-8');
      this.piData = decoder.decodeWithStream(fileData, { stream: false });
      this.isLoaded = true;
      console.info('Pi data loaded successfully, length: ' + this.piData.length);
    } catch (err) {
      const error = err as Error;
      console.error('Failed to load pi data: ' + error.message);
      throw new Error('Failed to load pi data');
    }
  }
  
  /**
   * 获取总页数
   */
  public getTotalPages(): number {
    if (!this.isLoaded || this.piData.length === 0) {
      return 0;
    }

    // 去掉"3."，剩余的是小数部分
    const decimalPart = this.piData.substring(2);
    const decimalLength = decimalPart.length;

    // 第一页显示56个小数，后续每页56个
    if (decimalLength <= PiDataManager.FIRST_PAGE_DIGITS) {
      return 1;
    }

    const remainingDigits = decimalLength - PiDataManager.FIRST_PAGE_DIGITS;
    return 1 + Math.ceil(remainingDigits / PiDataManager.DIGITS_PER_PAGE);
  }
  
  /**
   * 获取指定页的数据
   * @param pageIndex 页码（从0开始）
   * @returns 该页的圆周率数字字符串
   */
  public getPageData(pageIndex: number): string {
    if (!this.isLoaded || pageIndex < 0) {
      return '';
    }

    if (pageIndex === 0) {
      // 第一页：3. + 105个小数
      const endIndex = Math.min(2 + PiDataManager.FIRST_PAGE_DIGITS, this.piData.length);
      return this.piData.substring(0, endIndex);
    } else {
      // 后续页：每页105个数字
      const startIndex = 2 + PiDataManager.FIRST_PAGE_DIGITS + (pageIndex - 1) * PiDataManager.DIGITS_PER_PAGE;
      const endIndex = Math.min(startIndex + PiDataManager.DIGITS_PER_PAGE, this.piData.length);

      if (startIndex >= this.piData.length) {
        return '';
      }

      return this.piData.substring(startIndex, endIndex);
    }
  }
  
  /**
   * 获取指定页的起始和结束位数（小数点后）
   * @param pageIndex 页码（从0开始）
   * @returns PageRange 起始和结束位数
   */
  public getPageRange(pageIndex: number): PageRange {
    if (pageIndex === 0) {
      const range: PageRange = { start: 1, end: PiDataManager.FIRST_PAGE_DIGITS };
      return range;
    } else {
      const start = PiDataManager.FIRST_PAGE_DIGITS + (pageIndex - 1) * PiDataManager.DIGITS_PER_PAGE + 1;
      const end = start + PiDataManager.DIGITS_PER_PAGE - 1;
      const range: PageRange = { start, end };
      return range;
    }
  }
  
  /**
   * 根据小数点后的位数查找所在页码
   * @param position 小数点后的位数（从1开始）
   * @returns 页码（从0开始）
   */
  public getPageByPosition(position: number): number {
    if (position <= 0) {
      return 0;
    }

    if (position <= PiDataManager.FIRST_PAGE_DIGITS) {
      return 0;
    }

    const remainingPosition = position - PiDataManager.FIRST_PAGE_DIGITS;
    return Math.ceil(remainingPosition / PiDataManager.DIGITS_PER_PAGE);
  }
  
  /**
   * 获取指定位数在页面中的索引
   * @param position 小数点后的位数（从1开始）
   * @returns 在当前页数据中的字符索引（包括"3."等格式字符）
   */
  public getIndexInPage(position: number): number {
    const pageIndex = this.getPageByPosition(position);

    if (pageIndex === 0) {
      // 第一页：3. + 小数
      // position=1 对应索引2（"3."之后的第一个字符）
      return position + 1; // +1 是因为有"3."
    } else {
      // 后续页：计算在当前页中的位置
      const pageStart = PiDataManager.FIRST_PAGE_DIGITS + (pageIndex - 1) * PiDataManager.DIGITS_PER_PAGE + 1;
      // position - pageStart 得到在当前页中是第几个数字（从0开始）
      return position - pageStart;
    }
  }
  
  /**
   * 格式化页面数据为多行显示
   * @param pageData 页面数据
   * @param isFirstPage 是否为第一页
   * @returns 格式化后的行数组
   */
  public formatPageData(pageData: string, isFirstPage: boolean): string[] {
    const lines: string[] = [];
    
    if (isFirstPage) {
      // 第一页：第一行是"3."，后续每行7个数字
      lines.push('3.');
      const decimalPart = pageData.substring(2);
      for (let i = 0; i < decimalPart.length; i += PiDataManager.DIGITS_PER_LINE) {
        lines.push(decimalPart.substring(i, Math.min(i + PiDataManager.DIGITS_PER_LINE, decimalPart.length)));
      }
    } else {
      // 后续页：每行7个数字
      for (let i = 0; i < pageData.length; i += PiDataManager.DIGITS_PER_LINE) {
        lines.push(pageData.substring(i, Math.min(i + PiDataManager.DIGITS_PER_LINE, pageData.length)));
      }
    }
    
    return lines;
  }
  
  /**
   * 获取圆周率总长度
   */
  public getTotalLength(): number {
    return this.piData.length;
  }
}

