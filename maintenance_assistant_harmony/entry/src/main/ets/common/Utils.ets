import { AppStrings } from './Constants';

/**
 * 工具函数
 */
export class DateUtils {
  /**
   * 格式化日期为相对时间
   */
  static formatRelativeDate(timestamp: number): string {
    if (timestamp === 0) return AppStrings.NEVER;

    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return AppStrings.TODAY;
    if (diffDays === 1) return AppStrings.YESTERDAY;
    if (diffDays < 7) return `${diffDays}${AppStrings.DAYS_AGO}`;

    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}/${month}/${day}`;
  }

  /**
   * 格式化时间为 HH:mm
   */
  static formatTime(hour: number, minute: number): string {
    return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
  }

  /**
   * 解析时间字符串
   */
  static parseTime(timeStr: string): { hour: number; minute: number } {
    const parts = timeStr.split(':');
    return {
      hour: parseInt(parts[0], 10),
      minute: parseInt(parts[1], 10)
    };
  }

  /**
   * 获取当前时间戳
   */
  static now(): number {
    return Date.now();
  }
}

export class StringUtils {
  /**
   * 截断字符串
   */
  static truncate(str: string, maxLength: number): string {
    if (str.length <= maxLength) return str;
    return str.substring(0, maxLength) + '...';
  }

  /**
   * 生成唯一ID
   */
  static generateId(): string {
    return Date.now().toString();
  }
}
